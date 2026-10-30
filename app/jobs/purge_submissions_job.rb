class PurgeSubmissionsJob < ApplicationJob
  def perform
    Submission.where(status: "delivered").where("delivered_at < ?", 30.days.ago).delete_all
  end
end
