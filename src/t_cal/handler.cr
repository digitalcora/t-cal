require "http/server/handler"
require "log"
require "./alerts_api"
require "./calendar"

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
class TCal::Handler
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
      compat_param = context.request.query_params["compat"]?
      user_agent = context.request.headers["user-agent"]?

      log_request(extension, compat_param, user_agent)

      context.response.content_type = content_type(extension)
      context.response << response(compat_mode?(compat_param, user_agent))
    else
      call_next(context)
    end
  end

  private def compat_mode?(compat_param, user_agent)
    case compat_param
    when "true"  then true
    when "false" then false
    else              COMPLIANT_AGENTS.none? { |agent| user_agent =~ agent }
    end
  end

  private def content_type(extension)
    extension == "ics" ? "text/calendar" : "text/plain"
  end

  private def log_request(extension, compat_param, user_agent)
    Log.info &.emit(
      "Calendar request",
      format: extension,
      compat: compat_param.nil? ? "auto" : compat_param,
      agent: user_agent
    )
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
