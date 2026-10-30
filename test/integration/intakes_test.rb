require "test_helper"
class IntakesTest < ActionDispatch::IntegrationTest
  setup { IntakesController::RATE_LIMIT_STORE.clear; @headers = { "Origin" => "https://osnova-mind.ru" } }
  test "durable encrypted acceptance and repeated UUID" do
    data = intake_payload
    assert_difference("Submission.count", 1) { post "/v1/intake", params: data, as: :json, headers: @headers }
    assert_response :created
    id = response.parsed_body["id"]
    post "/v1/intake", params: data, as: :json, headers: @headers
    assert_response :created
    assert_equal id, response.parsed_body["id"]
    raw = Submission.connection.select_value("SELECT payload FROM submissions LIMIT 1")
    refute_includes raw, "example_test"
    data[:name] = "Другой"
    post "/v1/intake", params: data, as: :json, headers: @headers
    assert_response :conflict
  end
  test "rejects foreign and missing origin and handles preflight" do
    [nil, "https://evil.test"].each do |origin|
      post "/v1/intake", params: intake_payload, as: :json, headers: { "Origin" => origin }
      assert_response :forbidden
    end
    options "/v1/intake", headers: @headers
    assert_response :no_content
    assert_equal @headers["Origin"], response.headers["Access-Control-Allow-Origin"]
  end
  test "rejects absent consent malformed answers and invalid contact" do
    [{consent: false}, {answers: []}, {contact: "wrong!"}, {answers: ["bad"]}, {version: 2}].each do |change|
      post "/v1/intake", params: intake_payload.merge(change), as: :json, headers: @headers
      assert_response :unprocessable_entity
    end
    assert_equal 0, Submission.count
  end
  test "honeypot does not persist and rate limit rejects sixth request" do
    assert_no_difference("Submission.count") do
      post "/v1/intake", params: intake_payload.merge(website: "spam"), as: :json, headers: @headers
    end
    assert_response :created
    4.times { post "/v1/intake", params: intake_payload, as: :json, headers: @headers }
    post "/v1/intake", params: intake_payload, as: :json, headers: @headers
    assert_response :too_many_requests
  end
  test "conflicting answers cannot be mapped by forged index" do
    data = intake_payload
    data[:answers][0][:text] = "Новая формулировка"
    post "/v1/intake", params: data, as: :json, headers: @headers
    assert_response :created
    submission = Submission.last
    payload = Amo::LeadPayload.new(submission).to_h
    fields = payload.dig("_embedded", "contacts", 0, "custom_fields_values")
    refute fields.any? { |f| f["field_id"] == 1704425 }
    assert_includes Amo::LeadPayload.new(submission).summary, "Новая формулировка"
  end
end
