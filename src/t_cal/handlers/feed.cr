require "cache"
require "http/server/handler"
require "log"
require "raven"
require "../calendar/ical"
require "../v3_api/alert"
require "../v3_api/route"

# HTTP handler that serves an iCal feed based on MBTA Alerts. Handles the
# request if the path is `/alerts.ics` or `/alerts.txt`, with the "extension"
# determining the response content-type.
#
# If a `compat` query parameter is present and is the exact string `true` or
# `false`, the "compatible" calendar generation (see `TCal::Calendar::ICal`)
# will be enabled or disabled. Otherwise, the mode is chosen by comparing the
# `User-Agent` header to a hard-coded list of known calendar apps.
class TCal::Handlers::Feed
  include HTTP::Handler

  private COMPLIANT_AGENTS = StaticArray[/Google-Calendar-Importer/]
  private Log              = ::Log.for(self)

  # Creates a handler instance.
  def initialize
    # Should be `(Bool, String)` but:
    # https://github.com/crystal-cache/cache/issues/31
    @cache = Cache::MemoryStore(String, String)
      .new(expires_in: 1.minute, compress: false)
  end

  # :nodoc:
  def call(context)
    if context.request.path =~ /^\/alerts\.(ics|txt)$/
      extension = $~[1]
      compat_mode = compat_mode(context.request.query_params["compat"]?)
      user_agent = context.request.headers["user-agent"]?
      compat_enable = compat_enable?(compat_mode, user_agent)

      log(context.request, compat_mode, user_agent) if extension == "ics"

      calendar = @cache.fetch(compat_enable.to_s) do
        alerts = V3API.calendar_alerts_with_routes
        Calendar::ICal.new(alerts, compat_enable).to_s
      end

      context.response.content_type = content_type(extension)
      context.response << calendar
    else
      call_next(context)
    end
  end

  private def compat_enable?(compat_mode : Bool, user_agent)
    compat_mode
  end

  private def compat_enable?(compat_mode : Nil, user_agent)
    COMPLIANT_AGENTS.none? { |agent| user_agent =~ agent }
  end

  private def compat_mode(query_param)
    case query_param
    when "true"  then true
    when "false" then false
    else              nil
    end
  end

  private def content_type(extension)
    extension == "ics" ? "text/calendar" : "text/plain"
  end

  private def flatten_headers(headers : HTTP::Headers)
    headers.each_with_object({} of String => String) do |(k, v), hash|
      hash[k] = v.join ", "
    end
  end

  private def log(request, compat_mode, user_agent)
    compat_str = (compat_mode.nil? ? "auto" : compat_mode.to_s)

    Log.info &.emit("Requested", compat: compat_str, agent: user_agent)

    event = Raven::Event.from("CalendarRequest", level: :info)
    event.tags["feed.agent"] = user_agent
    event.tags["feed.compat"] = compat_str
    event.interface(:http,
      headers: flatten_headers(request.headers),
      query_string: request.query
    )
    spawn { Raven.send_event(event) }
  end
end
