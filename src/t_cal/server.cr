require "http/server"
require "logger"

class TCal::Server
  def initialize(@port : Int32, @log_io : IO = STDOUT)
    @server = HTTP::Server.new([
      HTTP::ErrorHandler.new,
      HTTP::LogHandler.new(@log_io),
      HTTP::CompressHandler.new
    ]) do |context|
      context.response.content_type = "text/plain"
      context.response.puts "Hello world!"
    end
  end

  def start
    address = @server.bind_tcp(@port)
    @log_io.puts("Server started on #{address}")
    @server.listen
  end
end
