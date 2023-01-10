require "http/server/handler"
require "log"
require "uri"

# HTTP handler that redirects requests using a non-canonical `Host`.
class TCal::Handlers::Canonize
  include HTTP::Handler

  private Log = ::Log.for(self)

  private record Origin, scheme : String?, host : String, port : Int32?

  # Creates a handler instance.
  # The `canonical_origin` must be a URL with at least a valid host component.
  # Components other than the scheme, host, and port are discarded.
  def initialize(canonical_origin : String)
    uri = URI.parse(canonical_origin)
    @origin = Origin.new(uri.scheme, uri.host.not_nil!, uri.port)
  end

  # :nodoc:
  def call(context)
    request_host = context.request.hostname

    if !request_host.nil? && request_host != @origin.host
      Log.info &.emit("Redirecting", from: request_host)

      location = URI.new(
        scheme: @origin.scheme,
        host: @origin.host,
        port: @origin.port,
        path: context.request.path,
        query: context.request.query
      )

      context.response.redirect(location, HTTP::Status::MOVED_PERMANENTLY)
    else
      call_next(context)
    end
  end
end
