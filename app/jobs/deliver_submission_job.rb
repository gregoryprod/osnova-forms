class DeliverSubmissionJob < ApplicationJob
  def perform(id)
    claimed = Submission.where(id: id, status: "pending").where("next_attempt_at IS NULL OR next_attempt_at <= ?", Time.current)
      .update_all(status: "delivering", lease_until: 5.minutes.from_now, attempts: Arel.sql("attempts + 1"), updated_at: Time.current)
    return unless claimed == 1
    row = Submission.find(id)
    payload = Amo::LeadPayload.new(row)
    client = Amo::Client.new
    unless row.amo_uid
      result = client.request(:post, "leads/unsorted/forms", [payload.to_h]).dig("_embedded", "unsorted", 0)
      raise Amo::Client::Ambiguous, "amo_response_unknown" unless result && result["uid"] && result.dig("_embedded", "leads", 0, "id")
      row.update!(amo_uid: result["uid"], amo_lead_id: result.dig("_embedded", "leads", 0, "id"), amo_contact_id: result.dig("_embedded", "contacts", 0, "id"))
    end
    client.request(:post, "leads/#{row.amo_lead_id}/notes", [{ note_type: "common", params: { text: payload.summary } }])
    row.update!(status: "delivered", delivered_at: Time.current, lease_until: nil, last_error: nil)
  rescue Amo::Client::Rejected => error
    # 5xx on POST can follow a successful write; reconcile rather than create duplicates.
    if error.code >= 500 && !row.amo_uid
      row.update!(status: "uncertain", last_error: error.message, lease_until: nil)
    else
      failed = row.attempts >= 20 || ![401, 403, 429, 500, 502, 503, 504].include?(error.code)
      row.update!(status: failed ? "failed" : "pending", last_error: error.message, next_attempt_at: [60 * (2 ** [row.attempts - 1, 6].min), 3600].min.seconds.from_now, lease_until: nil)
    end
  rescue Amo::Client::Ambiguous
    row.update!(status: row.amo_uid ? "pending" : "uncertain", next_attempt_at: 5.minutes.from_now, last_error: "amo_response_unknown", lease_until: nil)
  end
end
