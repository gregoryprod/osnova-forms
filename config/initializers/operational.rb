Rails.application.configure do
  config.cache_store = :memory_store, { size: 8.megabytes }
  config.active_job.queue_adapter = Rails.env.test? ? :test : :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } } if Rails.env.production?
  config.hosts << "forms.osnova-mind.ru" if Rails.env.production?
  config.public_file_server.headers = { "cache-control" => "public, max-age=300" }
end
