require "http/server/handler"
require "./alerts_api"
require "./calendar"

class TCal::Handler
  include HTTP::Handler

  private CACHE_TIME = Time::Span.new(hours: 0, minutes: 1, seconds: 0)
  # User-Agents for which "compat mode" can safely default to false
  private COMPLIANT_AGENTS = StaticArray[/Google-Calendar-Importer/]

  private record Cache, content : String, time : Time

  def initialize(@log_io : IO)
    @caches = {} of Bool => Cache
  end

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
