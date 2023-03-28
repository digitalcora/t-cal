require "cache"
require "http/server/handler"
require "log"
require "../calendar/ical"
require "../v3_api/alert"
require "../v3_api/route"

# HTTP handler that serves an iCal feed based on MBTA Alerts. Handles the
# request if the path is `/alerts.ics` or `/alerts.txt`, with the "extension"
# determining the response content-type.
class TCal::Handlers::Feed
  include HTTP::Handler

  private CacheKey = nil.to_s
  private Log      = ::Log.for(self)

  # Creates a handler instance.
  def initialize
    # Should be `(Nil, String)` but:
    # https://github.com/crystal-cache/cache/issues/31
    @cache = Cache::MemoryStore(String, String)
      .new(expires_in: 1.minute, compress: false)
  end

  # :nodoc:
  def call(context)
    if context.request.path =~ /^\/alerts\.(ics|txt)$/
      context.response.content_type = content_type($~[1])
      context.response << calendar()
    else
      call_next(context)
    end
  end

  private def calendar
    @cache.fetch(CacheKey) do
      alerts = V3API.calendar_alerts_with_routes
      Calendar::ICal.new(alerts).to_s
    end
  end

  private def content_type(extension)
    extension == "ics" ? "text/calendar" : "text/plain"
  end
end
