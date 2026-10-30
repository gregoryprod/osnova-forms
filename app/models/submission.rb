class Submission < ApplicationRecord
  encrypts :payload
  def data = JSON.parse(payload)
  def self.recoverable
    where(status: "pending").where("next_attempt_at IS NULL OR next_attempt_at <= ?", Time.current)
  end
end
