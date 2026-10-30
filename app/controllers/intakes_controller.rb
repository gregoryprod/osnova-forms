class IntakesController < ApplicationController
  ORIGINS = %w[https://osnova-mind.ru https://www.osnova-mind.ru].freeze
  RATE_LIMIT_STORE = ActiveSupport::Cache::MemoryStore.new(size: 8.megabytes)
  before_action :check_origin
  rate_limit to: 5, within: 1.minute, only: :create, store: RATE_LIMIT_STORE, with: -> { render json: { ok: false }, status: 429 }
  def preflight = head(:no_content)
  def create
    return head(:content_too_large) if request.raw_post.bytesize > 16.kilobytes
    return render(json: { ok: false }, status: 415) unless request.media_type == "application/json"
    raw = JSON.parse(request.raw_post)
    return render(json: { ok: false }, status: 422) unless raw.is_a?(Hash)
    return render(json: { ok: true, id: SecureRandom.uuid }, status: :created) if raw["website"].present?
    errors = IntakeValidator.errors(raw)
    return render(json: { ok: false, errors: errors }, status: 422) if errors.any?
    data = raw.slice("version", "form", "answers", "name", "contact", "consent", "page")
    data["name"] = data["name"].strip
    data["contact"] = IntakeValidator.contact(data["contact"])
    data["referrer"] = raw["referrer"].to_s.first(2048)
    data["utm"] = %w[utm_source utm_medium utm_campaign utm_content utm_term].to_h { |key| [key, raw.fetch("utm", {}).is_a?(Hash) ? raw.fetch("utm", {})[key].to_s.first(500) : ""] }
    digest = Digest::SHA256.hexdigest(JSON.generate(data))
    record = Submission.find_by(client_submission_id: raw["client_submission_id"])
    unless record
      data["received_at"] = Time.current.iso8601
      data["ip"] = request.remote_ip
      data["legal"] = JSON.parse(Rails.root.join("config/legal_versions.json").read)
      record = Submission.create!(client_submission_id: raw["client_submission_id"], payload: JSON.generate(data), payload_digest: digest)
    end
    return render(json: { ok: false, errors: { client_submission_id: "conflict" } }, status: :conflict) unless record.payload_digest == digest
    # The durable row is the outbox. A recurring dispatcher recovers enqueue failures.
    begin
      DeliverSubmissionJob.perform_later(record.id) if record.status == "pending"
    rescue StandardError
      Rails.logger.error("enqueue_failed submission_id=#{record.id}")
    end
    render json: { ok: true, id: record.client_submission_id }, status: :created
  rescue JSON::ParserError
    render json: { ok: false }, status: :bad_request
  rescue ActiveRecord::RecordNotUnique
    retry
  end
  private
  def check_origin
    return head(:forbidden) unless ORIGINS.include?(request.headers["Origin"])
    response.set_header("Access-Control-Allow-Origin", request.headers["Origin"])
    response.set_header("Vary", "Origin")
    response.set_header("Access-Control-Allow-Methods", "POST, OPTIONS")
    response.set_header("Access-Control-Allow-Headers", "Content-Type")
    response.set_header("Access-Control-Max-Age", "600")
  end
end
