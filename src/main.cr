require "log"
require "raven"
require "./t_cal"
require "./t_cal/server"

# Entrypoint for starting the TCal web server.

# https://github.com/crystal-lang/crystal/blob/3184e19/src/log/format.cr#L201
Log.define_formatter TimelessFormat,
  "#{severity} - #{source(after: ": ")}#{message}" \
  "#{data(before: " -- ")}#{context(before: " -- ")}#{exception}"
Log.setup_from_env(backend: Log::IOBackend.new(formatter: TimelessFormat))

Raven.configure do |config|
  config.async = true
end

STDOUT.sync = true
host = ENV.fetch("HOST", "127.0.0.1")
port = ENV.fetch("PORT", "8080").to_i
origin = ENV.fetch("ORIGIN", "http://localhost:#{port}")
TCal::Server.new(host, port, origin).start
