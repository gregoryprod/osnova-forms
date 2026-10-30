class DispatchPendingJob < ApplicationJob
  def perform
    Submission.where(status: "delivering").where("lease_until < ?", Time.current).find_each do |row|
      row.update!(status: row.amo_uid ? "pending" : "uncertain", lease_until: nil, last_error: "interrupted_delivery")
      AlertJob.perform_later(row.id, "interrupted_delivery")
    end
    Submission.recoverable.limit(100).pluck(:id).each { |id| DeliverSubmissionJob.perform_later(id) }
  end
end
