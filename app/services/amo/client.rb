require "net/http"
module Amo
  class Client
    class Rejected < StandardError
      attr_reader :code
      def initialize(code)
        @code = code
        super("amo_http_#{code}")
      end
    end
    class Ambiguous < StandardError; end
    def request(method, path, body = nil)
      base = ENV.fetch("AMO_BASE_URL", "https://piwyjawik.amocrm.ru")
      raise "invalid_amo_base" unless base == "https://piwyjawik.amocrm.ru"
      uri = URI("#{base}/api/v4/#{path}")
      req = (method == :get ? Net::HTTP::Get : Net::HTTP::Post).new(uri)
      req["Authorization"] = "Bearer #{ENV.fetch("AMO_TOKEN")}"
      req["Content-Type"] = "application/json"
      req.body = JSON.generate(body) if body
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 15, write_timeout: 10) { |http| http.request(req) }
      raise Rejected.new(response.code.to_i) unless response.code.to_i.between?(200, 299)
      JSON.parse(response.body.presence || "{}")
    rescue Timeout::Error, IOError, SystemCallError, OpenSSL::SSL::SSLError, JSON::ParserError
      raise Ambiguous, "amo_response_unknown"
    end
  end
end
