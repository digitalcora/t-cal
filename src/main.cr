require "./t_cal/rollbar"
require "./t_cal/server"

# Entrypoint for starting the TCal web server.

STDOUT.sync = true

host = ENV.fetch("HOST", "127.0.0.1")
port = ENV.fetch("PORT", "8080").to_i

rollbar = nil
rollbar_env = ENV["ROLLBAR_ENVIRONMENT"]?
rollbar_token = ENV["ROLLBAR_ACCESS_TOKEN"]?
if rollbar_env && rollbar_token
  rollbar = TCal::Rollbar.new(STDOUT, rollbar_token, rollbar_env)
end

TCal::Server.new(host, port, STDOUT, rollbar).start
