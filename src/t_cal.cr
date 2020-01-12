require "./t_cal/server"

STDOUT.sync = true
host = ENV.fetch("HOST", "127.0.0.1")
port = ENV.fetch("PORT", "8080").to_i
TCal::Server.new(host, port, STDOUT).start
