require "net/http"
class AlertJob < ApplicationJob
  retry_on StandardError, wait: 5.minutes, attempts: 12
  def perform(id, code)
    token = ENV.fetch("ALERT_BOT_TOKEN")
    chat_id = ENV.fetch("ALERT_CHAT_ID")
    uri = URI(ENV.fetch("ALERT_API_ROOT", "https://api.telegram.org"))
    unless uri.is_a?(URI::HTTPS) && uri.host.present? && uri.userinfo.nil? && uri.query.nil? && uri.fragment.nil?
      raise "alert_api_root_invalid"
    end
    uri.path = "#{uri.path.sub(%r{/+\z}, '')}/bot#{token}/sendMessage"
    req = Net::HTTP::Post.new(uri)
    req.set_form_data(chat_id: chat_id, text: "osnova-forms: submission_id=#{id}; event=#{code}")
    result = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 10) { |http| http.request(req) }
    raise "alert_failed" unless result.code.to_i == 200 && JSON.parse(result.body)["ok"] == true
  rescue URI::InvalidURIError
    raise "alert_api_root_invalid"
  rescue Timeout::Error, IOError, SystemCallError, JSON::ParserError, OpenSSL::SSL::SSLError
    raise "alert_transport_failed"
  end
end
