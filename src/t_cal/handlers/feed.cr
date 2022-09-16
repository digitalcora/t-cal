require "http/server/handler"
require "log"
require "raven"
require "../alerts_api"
require "../calendar"

# HTTP handler (see `HTTP::Handler`) that serves iCal data for MBTA alerts.
# Handles the request if the path is `/alerts.ics` or `/alerts.txt`, with the
# response content-type determined by the "extension".
#
# If a `compat` query parameter is present and is the exact string `true` or
# `false`, the "compatible" calendar generation (see `TCal::Calendar`) will be
# enabled or disabled respectively. Otherwise, the mode is chosen by comparing
# the `User-Agent` header to a hard-coded list of known calendar apps.
#
# Response bodies are cached in memory for a short time, to avoid hammering the
# MBTA API used to generate the calendar.
class TCal::Handlers::Feed
  include HTTP::Handler

  private CACHE_DURATION   = Time::Span.new(hours: 0, minutes: 1, seconds: 0)
  private COMPLIANT_AGENTS = StaticArray[/Google-Calendar-Importer/]
  private Log              = ::Log.for(self)

  private record Cache, content : String, time : Time

  # Creates a handler instance.
  def initialize
    @caches = {} of Bool => Cache
  end

  # :nodoc:
  def call(context)
    if context.request.path =~ /^\/alerts\.(ics|txt)$/
      extension = $~[1]
      compat_mode = compat_mode(context.request.query_params["compat"]?)
      user_agent = context.request.headers["user-agent"]?

      log_request(context.request, extension, compat_mode, user_agent)

      context.response.content_type = content_type(extension)
      context.response << response(compat_enable?(compat_mode, user_agent))
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

  private def log_request(request, extension, compat_mode, user_agent)
    compat_str = (compat_mode.nil? ? "auto" : compat_mode.to_s)

    Log.info &.emit("Requested",
      extension: extension, compat: compat_str, agent: user_agent)

    event = Raven::Event.from("CalendarRequest", level: :info)
    event.tags["feed.extension"] = extension
    event.tags["feed.compat"] = compat_str
    event.interface(:http,
      headers: flatten_headers(request.headers),
      query_string: request.query
    )
    spawn { Raven.send_event(event) }
  end

  private def response(compat_mode)
    if (cache = @caches[compat_mode]?) && Time.utc - cache.time < CACHE_DURATION
      cache.content
    else
      alerts = AlertsAPI.get!
      calendar = Calendar.new(alerts, compat_mode).to_s
      @caches[compat_mode] = Cache.new(calendar, Time.utc)
      calendar
    end
  end
end
