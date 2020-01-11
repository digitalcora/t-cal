require "./t_cal/server"

port = ENV.fetch("PORT", "8080").to_i
TCal::Server.new(port).start
