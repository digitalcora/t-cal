require "http/server/handler"
require "./calendar"

class TCal::Handler
  include HTTP::Handler

  private ALERTS_URL = "https://api-v3.mbta.com/alerts?filter[route_type]=0,1,2"
  private CACHE_TIME = Time::Span.new(hours: 0, minutes: 1, seconds: 0)

  @cache : String?
  @cached_at : Time

  def initialize
    @cached_at = CACHE_TIME.ago
  end

  def call(context)
    if context.request.path =~ /^\/shuttles\.(ics|txt)$/
      context.response.content_type =
        ($~[1] == "ics" ? "text/calendar" : "text/plain")

      handle(context)
    else
      call_next(context)
    end
  end

  private def handle(context)
    if @cache && @cached_at && Time.utc - @cached_at < CACHE_TIME
      context.response << @cache
    else
      HTTP::Client.get(ALERTS_URL) do |api_response|
        case api_response.status
        when HTTP::Status::OK
          alerts = TCal::JSONAPI::Response.from_json(api_response.body_io).data
          calendar = TCal::Calendar.new(alerts).to_s
          @cache = calendar
          @cached_at = Time.utc
          context.response << calendar
        else
          raise "Unexpected API response: #{api_response.body_io.gets_to_end}"
        end
      end
    end
  end
end
