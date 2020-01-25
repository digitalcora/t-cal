require "http/server/handler"
require "./alerts_api"
require "./calendar"

# HTTP handler (see `HTTP::Handler`) that serves iCal data for MBTA alerts.
# Handles the request if the path is `/alerts.ics` or `/alerts.txt`, with the
# response content-type determined by the "extension".
#
# If a `compat` query parameter is present and is the exact string `true` or
# `false`, the "compatible" calendar generation (see `TCal::Calendar`) will be
# enabled or disabled respectively. Otherwise, the mode is chosen by comparing
# the `User-Agent` header to a hard-coded list of known RFC-compliant apps. The
# header is also logged, to aid in adding it to the list if needed.
#
# Response bodies are cached in memory for a short time, to avoid hammering the
# MBTA API used to generate the calendar.
class TCal::Handler
  include HTTP::Handler

  private CACHE_TIME = Time::Span.new(hours: 0, minutes: 1, seconds: 0)

  private COMPLIANT_AGENTS = StaticArray[/Google-Calendar-Importer/]

  # :nodoc:
  record Cache, content : String, time : Time

  # Creates a handler instance that will output logs to `log_io`.
  def initialize(@log_io : IO)
    @caches = {} of Bool => Cache
  end

  # :nodoc:
  def call(context)
    if context.request.path =~ /^\/alerts\.(ics|txt)$/
      context.response.content_type =
        ($~[1] == "ics" ? "text/calendar" : "text/plain")

      respond(context.response, compat_mode?(context.request))
    else
      call_next(context)
    end
  end

  private def compat_mode?(request)
    case request.query_params["compat"]?
    when "true"  then true
    when "false" then false
    else
      user_agent = request.headers["user-agent"]?
      @log_io.puts "User-Agent: #{user_agent}"
      COMPLIANT_AGENTS.none? { |agent| user_agent =~ agent }
    end
  end

  private def respond(response, compat_mode)
    if (cache = @caches[compat_mode]?) && Time.utc - cache.time < CACHE_TIME
      response << cache.content
    else
      alerts = AlertsAPI.get!
      calendar = Calendar.new(alerts, compat_mode).to_s
      @caches[compat_mode] = Cache.new(calendar, Time.utc)
      response << calendar
    end
  end
end
