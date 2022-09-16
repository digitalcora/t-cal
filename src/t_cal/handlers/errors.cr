require "http/server/handler"
require "raven/integrations/http/handler"

# HTTP handler that reports exceptions to Sentry.
class TCal::Handlers::Errors
  include HTTP::Handler
  include Raven::HTTPHandler

  def build_raven_culprit_context(context)
    nil
  end

  def build_raven_http_url(context)
    context.request.path
  end

  def build_raven_http_data(context)
    {} of String => String
  end
end
