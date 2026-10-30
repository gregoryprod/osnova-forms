require "test_helper"

class AlertJobTest < ActiveSupport::TestCase
  setup do
    @previous_env = %w[ALERT_API_ROOT ALERT_BOT_TOKEN ALERT_CHAT_ID].to_h { |key| [key, ENV[key]] }
    ENV["ALERT_BOT_TOKEN"] = "123456:synthetic-test-token"
    ENV["ALERT_CHAT_ID"] = "-100123456"
    ENV.delete("ALERT_API_ROOT")
  end

  teardown do
    @previous_env.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end

  test "uses Telegram by default" do
    request = stub_request(:post, "https://api.telegram.org/bot123456:synthetic-test-token/sendMessage")
      .with(body: { "chat_id" => "-100123456", "text" => "osnova-forms: submission_id=42; event=token" })
      .to_return(status: 200, body: '{"ok":true}')
    AlertJob.new.perform(42, "token")
    assert_requested request, times: 1
  end

  test "uses configured proxy root with optional prefix and trailing slash" do
    ["https://plain.example.test", "https://slash.example.test/", "https://prefix.example.test/telegram/"].each do |root|
      ENV["ALERT_API_ROOT"] = root
      request = stub_request(:post, "#{root.delete_suffix('/')}/bot123456:synthetic-test-token/sendMessage")
        .with(body: { "chat_id" => "-100123456", "text" => "osnova-forms: submission_id=42; event=delivery" })
        .to_return(status: 200, body: '{"ok":true}')
      AlertJob.new.perform(42, "delivery")
      assert_requested request
    end
    assert_not_requested :post, /api\.telegram\.org/
  end

  test "rejects invalid root without exposing credentials" do
    ENV["ALERT_API_ROOT"] = "http://alerts.example.test"
    error = assert_raises(RuntimeError) { AlertJob.new.perform(42, "token") }
    assert_equal "alert_api_root_invalid", error.message
    assert_not_requested :post, /.*/
  end
end
