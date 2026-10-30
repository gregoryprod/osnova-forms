class IntakeCatalog
  def self.questions
    @questions ||= JSON.parse(Rails.root.join("config/intake_catalog.json").read).freeze
  end
end
