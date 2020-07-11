require "log"
require "./t_cal/server"

# Entrypoint for starting the TCal web server.

# https://github.com/crystal-lang/crystal/blob/0.35.1/src/log/format.cr#L197
Log.define_formatter TimelessFormat,
  "#{severity} - #{source(after: ": ")}#{message}" \
  "#{data(before: " -- ")}#{context(before: " -- ")}#{exception}"
Log.setup_from_env(backend: Log::IOBackend.new(formatter: TimelessFormat))

STDOUT.sync = true
host = ENV.fetch("HOST", "127.0.0.1")
port = ENV.fetch("PORT", "8080").to_i
TCal::Server.new(host, port).start
