require "http/server"
require "logger"
require "./handler"
require "./root_handler"

# The TCal HTTP server.
class TCal::Server
  # Creates a server instance.
  #
  # When started the server will bind to `address` on the specified `port`, and
  # write logs to `log_io`.
  #
  # Included behaviors:
  # * Catches exceptions and returns a 500 response
  # * Logs request methods, paths, and execution times
  # * Gzips responses if the client indicates support
  def initialize(@address : String, @port : Int32, @log_io : IO)
    @server = HTTP::Server.new([
      HTTP::ErrorHandler.new,
      HTTP::LogHandler.new(@log_io),
      HTTP::CompressHandler.new,
      TCal::Handler.new(@log_io),
      TCal::RootHandler.new,
    ])
  end

  # Starts the server.
  # Blocks until the process is terminated.
  def start
    address = @server.bind_tcp(@address, @port)
    @log_io.puts("Server started on #{address}")
    @server.listen
  end
end
