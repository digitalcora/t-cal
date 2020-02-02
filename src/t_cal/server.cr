require "http/server"
require "logger"
require "./error_handler"
require "./handler"
require "./rollbar"
require "./site/handler"

# The TCal HTTP server.
class TCal::Server
  # Creates a server instance.
  #
  # When started the server will bind to `host` on the specified `port`, write
  # logs to `log_io`, and optionally send error reports using `rollbar`.
  #
  # Included behaviors:
  # * Catches exceptions and returns a 500 response
  # * Logs request methods, paths, and execution times
  # * Gzips responses if the client indicates support
  def initialize(
    @host : String,
    @port : Int32,
    @log_io : IO,
    @rollbar : Rollbar?
  )
    @server = HTTP::Server.new([
      TCal::ErrorHandler.new(@log_io, @rollbar),
      HTTP::LogHandler.new(@log_io),
      HTTP::CompressHandler.new,
      TCal::Handler.new(@log_io),
      TCal::Site::Handler.new,
    ])
  end

  # Starts the server.
  # Blocks until the process is terminated.
  def start
    address = @server.bind_tcp(@host, @port)
    @log_io.puts("Server started on #{address}")
    @server.listen
  end
end
