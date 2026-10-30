namespace :amo do
  desc "Read-only token and pipeline check (no tokens or PII in output)"
  task check: :environment do
    client = Amo::Client.new
    account = client.request(:get, "account")
    abort "unexpected_account" unless account["id"] == 33338146
    pipeline = client.request(:get, "leads/pipelines/11440118")
    abort "unsorted_disabled" unless pipeline["is_unsorted_on"]
    puts "account=33338146 pipeline=11440118 unsorted=enabled"
  end
end
namespace :submissions do
  desc "Print operational IDs and statuses only"
  task status: :environment do
    puts Submission.group(:status).count.to_json
    Submission.where(status: %w[failed uncertain]).pluck(:id, :status, :last_error, :amo_lead_id).each { |row| puts row.to_json }
  end
end
