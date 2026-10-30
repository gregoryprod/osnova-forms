threads_count = ENV.fetch("RAILS_MAX_THREADS", 5).to_i
threads threads_count, threads_count
bind "tcp://127.0.0.1:#{ENV.fetch("PORT", 3100)}"
plugin :tmp_restart
plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"] == "true"
