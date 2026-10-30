ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"
WebMock.disable_net_connect!
class ActiveSupport::TestCase
  def intake_payload
    { version: 1, form: "diagnostic-intake", client_submission_id: SecureRandom.uuid,
      name: "Тест", contact: "@example_test", consent: true, page: "https://osnova-mind.ru/",
      answers: IntakeCatalog.questions.map { |q| { id: q["id"], index: 0, text: q["options"][0] } } }
  end
end
