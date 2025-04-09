require "http/server/handler"
require "log"
require "../cache"
require "../calendar/ical"

# HTTP handler that serves an iCal feed based on MBTA Alerts. Handles the
# request if the path is `/alerts.ics` or `/alerts.txt`, with the "extension"
# determining the response content-type.
class TCal::Handlers::Feed
  include HTTP::Handler

  private Log = ::Log.for(self)

  # Creates a handler instance.
  def initialize
    @cache = TCal::Cache(Nil, String).new(expires_in: 1.minute)
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
    @cache.fetch(nil) do
      Calendar::ICal.new.to_s
    end
  end

  private def content_type(extension)
    extension == "ics" ? "text/calendar" : "text/plain"
  end
end
