class IntakeValidator
  UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
  def self.contact(value)
    return unless value.is_a?(String) && value.length <= 120
    text = value.strip
    if text.match?(/\A(?:@)?[a-z][a-z0-9_]{4,31}\z/i) || text.match?(/\A(?:https?:\/\/)?t\.me\/[a-z][a-z0-9_]{4,31}\/?\z/i)
      "@#{text.sub(/\A(?:https?:\/\/)?t\.me\//i, "").delete_prefix("@").delete_suffix("/").downcase}"
    elsif text.match?(/\A\+?[\d\s().-]+\z/) && text.gsub(/\D/, "").length.between?(7, 15)
      digits = text.gsub(/\D/, "")
      digits = "7#{digits[1..]}" if digits.length == 11 && digits.start_with?("8")
      "+#{digits}"
    end
  end
  def self.errors(data)
    errors = {}
    errors[:version] = "unsupported" unless data["version"] == 1 && data["form"] == "diagnostic-intake"
    errors[:client_submission_id] = "invalid" unless data["client_submission_id"].is_a?(String) && UUID.match?(data["client_submission_id"])
    errors[:name] = "invalid" unless data["name"].is_a?(String) && data["name"].strip.length.between?(1, 100)
    errors[:contact] = "invalid" unless contact(data["contact"])
    errors[:consent] = "required" unless data["consent"] == true
    answers = data["answers"]
    valid = answers.is_a?(Array) && answers.size == 7 && answers.each_with_index.all? do |answer, i|
      answer.is_a?(Hash) && answer["id"] == "q#{i + 1}" && answer["index"].is_a?(Integer) &&
        answer["index"].between?(0, 30) && answer["text"].is_a?(String) && answer["text"].strip.length.between?(1, 500)
    end
    errors[:answers] = "invalid" unless valid
    errors[:page] = "invalid" unless data["page"].is_a?(String) && data["page"].length <= 2048 && data["page"].match?(/\Ahttps:\/\/(?:www\.)?osnova-mind\.ru(?:\/|\z)/)
    errors
  end
end
