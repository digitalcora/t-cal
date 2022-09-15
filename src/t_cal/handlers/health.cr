require "http/server/handler"

# HTTP handler that responds to health check requests at `/_health`.
class TCal::Handlers::Health
  include HTTP::Handler

  # :nodoc:
  def call(context)
    if context.request.path == "/_health"
      context.response.status = HTTP::Status::OK
    else
      call_next(context)
    end
  end
end
