require "test_helper"
class DeliverSubmissionJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  setup do
    ENV["AMO_TOKEN"] = "synthetic-test-token"
    data = intake_payload.stringify_keys.merge("received_at" => Time.current.iso8601, "ip" => "127.0.0.1", "legal" => {}, "utm" => {})
    @row = Submission.create!(client_submission_id: SecureRandom.uuid, payload: data.to_json, payload_digest: "test")
    @url = "https://piwyjawik.amocrm.ru/api/v4/leads/unsorted/forms"
    @created = { _embedded: { unsorted: [{ uid: "synthetic-uid", _embedded: { leads: [{id: 101}], contacts: [{id: 202}] } }] } }.to_json
  end
  teardown { ENV.delete("AMO_TOKEN") }
  test "missing empty and whitespace referrer fall back to form page without changing original data" do
    [nil, "", " \t"].each do |referrer|
      data = @row.data.merge("referrer" => referrer)
      @row.update!(payload: data.to_json)
      assert_equal data["page"], Amo::LeadPayload.new(@row).to_h.dig("metadata", "referer")
      assert_equal data, @row.data
    end
  end
  test "nonempty referrer is preserved" do
    referrer = "https://example.test/source"
    @row.update!(payload: @row.data.merge("referrer" => referrer).to_json)
    assert_equal referrer, Amo::LeadPayload.new(@row).to_h.dig("metadata", "referer")
  end
  test "creates unsorted with correct enums then summary and is repeat-safe" do
    create = stub_request(:post, @url).with { |r|
      p = JSON.parse(r.body).first
      fields = p.dig("_embedded", "contacts", 0, "custom_fields_values")
      p.dig("metadata", "referer") == @row.data["page"] && p["pipeline_id"] == 11440118 && fields.any? { |f| f["field_id"] == 1704425 && f["values"][0]["enum_id"] == 1126919 }
    }.to_return(status: 200, body: @created)
    note = stub_request(:post, "https://piwyjawik.amocrm.ru/api/v4/leads/101/notes").to_return(status: 200, body: "{}")
    2.times { DeliverSubmissionJob.perform_now(@row.id) }
    assert_equal "delivered", @row.reload.status
    assert_equal 101, @row.amo_lead_id
    assert_requested create, times: 1
    assert_requested note, times: 1
  end
  test "401 keeps durable request and retries after recovery" do
    stub_request(:post, @url).to_return(status: 401)
    assert_no_enqueued_jobs { DeliverSubmissionJob.perform_now(@row.id) }
    assert_equal "pending", @row.reload.status
    assert_equal "amo_http_401", @row.last_error
    @row.update!(next_attempt_at: 1.second.ago)
    stub_request(:post, @url).to_return(status: 200, body: @created)
    stub_request(:post, "https://piwyjawik.amocrm.ru/api/v4/leads/101/notes").to_return(status: 200, body: "{}")
    DeliverSubmissionJob.perform_now(@row.id)
    assert_equal "delivered", @row.reload.status
  end
  test "timeout after POST is uncertain and never blindly creates duplicate" do
    create = stub_request(:post, @url).to_timeout
    DeliverSubmissionJob.perform_now(@row.id)
    assert_equal "uncertain", @row.reload.status
    DeliverSubmissionJob.perform_now(@row.id)
    assert_requested create, times: 1
  end
  test "summary retry does not recreate CRM lead" do
    create = stub_request(:post, @url).to_return(status: 200, body: @created)
    stub_request(:post, "https://piwyjawik.amocrm.ru/api/v4/leads/101/notes").to_return(status: 503)
    DeliverSubmissionJob.perform_now(@row.id)
    assert_equal "pending", @row.reload.status
    assert_equal "synthetic-uid", @row.amo_uid
    @row.update!(next_attempt_at: 1.second.ago)
    stub_request(:post, "https://piwyjawik.amocrm.ru/api/v4/leads/101/notes").to_return(status: 200, body: "{}")
    DeliverSubmissionJob.perform_now(@row.id)
    assert_requested create, times: 1
    assert_equal "delivered", @row.reload.status
  end
  test "interrupted delivery is held for reconciliation and unqueued row recovered" do
    @row.update!(status: "delivering", lease_until: 1.minute.ago)
    DispatchPendingJob.perform_now
    assert_equal "uncertain", @row.reload.status
    @row.update!(status: "pending")
    assert_enqueued_with(job: DeliverSubmissionJob, args: [@row.id]) { DispatchPendingJob.perform_now }
  end
  test "purge deletes only delivered requests older than retention" do
    @row.update!(status: "delivered", delivered_at: 31.days.ago)
    PurgeSubmissionsJob.perform_now
    refute Submission.exists?(@row.id)
  end
end
