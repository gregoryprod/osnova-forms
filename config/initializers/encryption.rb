Rails.application.configure do
  config.active_record.encryption.primary_key = ENV.fetch("ENCRYPTION_PRIMARY_KEY") { Rails.env.production? ? raise("ENCRYPTION_PRIMARY_KEY missing") : "test-primary-key-not-for-production" }
  config.active_record.encryption.deterministic_key = ENV.fetch("ENCRYPTION_DETERMINISTIC_KEY") { Rails.env.production? ? raise("ENCRYPTION_DETERMINISTIC_KEY missing") : "test-deterministic-not-for-production" }
  config.active_record.encryption.key_derivation_salt = ENV.fetch("ENCRYPTION_KEY_DERIVATION_SALT") { Rails.env.production? ? raise("ENCRYPTION_KEY_DERIVATION_SALT missing") : "test-salt-not-for-production" }
end
