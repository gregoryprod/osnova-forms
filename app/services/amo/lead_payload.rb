module Amo
  class LeadPayload
    def initialize(submission)
      @submission = submission
      @data = submission.data
    end
    def to_h
      fields = @data.fetch("answers").filter_map do |answer|
        q = IntakeCatalog.questions.find { |question| question["id"] == answer["id"] }
        index = q["options"].index(answer["text"])
        next if index.nil?
        field(q["field_id"], { "enum_id" => q["enum_ids"][index] })
      end
      fields << field(1704187, { "value" => true })
      fields << field(1704587, { "value" => "Сайт: анкета диагностики" })
      if @data["contact"].start_with?("@")
        fields << field(1704423, { "value" => @data["contact"] })
      else
        fields << { "field_code" => "PHONE", "values" => [{ "value" => @data["contact"], "enum_code" => "WORK" }] }
      end
      lead = { "name" => "Анкета сайта — #{@data["name"]}", "_embedded" => { "tags" => [{ "name" => "сайт" }, { "name" => "анкета-диагностика" }] } }
      tracking = @data.fetch("utm", {}).filter_map do |code, value|
        { "field_code" => code.upcase, "values" => [{ "value" => value }] } if value.present?
      end
      lead["custom_fields_values"] = tracking if tracking.any?
      {
        "source_uid" => @submission.client_submission_id,
        "source_name" => "Анкета osnova-mind.ru",
        "pipeline_id" => 11440118,
        "metadata" => { "form_id" => "osnova-intake", "form_name" => "Анкета диагностики", "form_page" => @data["page"], "ip" => @data["ip"], "form_sent_at" => Time.iso8601(@data["received_at"]).to_i, "referer" => @data["referrer"] },
        "_embedded" => { "leads" => [lead], "contacts" => [{ "name" => @data["name"], "custom_fields_values" => fields }] }
      }
    end
    def summary
      lines = @data.fetch("answers").map do |a|
        q = IntakeCatalog.questions.find { |question| question["id"] == a["id"] }
        "#{q["title"]}: #{a["text"]}"
      end
      (lines + ["Согласие: #{@data["received_at"]}", "Документы: #{@data["legal"].to_json}", "Страница: #{@data["page"]}", "UTM: #{@data["utm"].to_json}", "ID заявки: #{@submission.client_submission_id}"]).join("\n")
    end
    private
    def field(id, value) = { "field_id" => id, "values" => [value] }
  end
end
