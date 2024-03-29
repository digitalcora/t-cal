require "http/server"
require "log"
require "./handlers/*"

# The TCal HTTP server.
class TCal::Server
  private Log = ::Log.for(self)

  # Creates a server instance.
  #
  # When started the server will bind to `address` on the specified `port`.
  # The specified canonical `origin` is passed to `TCal::Handlers::Canonize`.
  def initialize(@address : String, @port : Int32, origin : String)
    @server = HTTP::Server.new([
      HTTP::ErrorHandler.new,
      TCal::Handlers::Errors.new,
      TCal::Handlers::Health.new,
      HTTP::LogHandler.new,
      TCal::Handlers::Canonize.new(origin),
      HTTP::StaticFileHandler.new(
        "#{__DIR__}/assets",
        directory_listing: false
      ),
      HTTP::CompressHandler.new,
      TCal::Handlers::Feed.new,
      TCal::Handlers::Site.new(origin),
    ])
  end

  # Starts the server.
  # Blocks until the process is terminated.
  def start
    address = @server.bind_tcp(@address, @port)
    Log.info { "Listening on #{address}" }
    @server.listen
  end
end
