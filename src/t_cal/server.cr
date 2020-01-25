require "http/server"
require "logger"
require "./handler"
require "./root_handler"

class TCal::Server
  def initialize(@address : String, @port : Int32, @log_io : IO)
    @server = HTTP::Server.new([
      HTTP::ErrorHandler.new,
      HTTP::LogHandler.new(@log_io),
      HTTP::CompressHandler.new,
      TCal::Handler.new(@log_io),
      TCal::RootHandler.new,
    ])
  end

  def start
    address = @server.bind_tcp(@address, @port)
    @log_io.puts("Server started on #{address}")
    @server.listen
  end
end
