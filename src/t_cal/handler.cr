require "http/server/handler"
require "./calendar"

class TCal::Handler
  include HTTP::Handler

  private ALERTS_URL = "https://api-v3.mbta.com/alerts?filter[route_type]=0,1,2"

  def call(context)
    if context.request.path == "/shuttles.ics"
      HTTP::Client.get(ALERTS_URL) do |response|
        case response.status
        when HTTP::Status::OK
          alerts = TCal::JSONAPI::Response.from_json(response.body_io).data
          context.response.content_type = "text/calendar"
          context.response << TCal::Calendar.new(alerts)
        else
          raise "Unexpected API response: #{response.body_io.gets_to_end}"
        end
      end
    else
      call_next(context)
    end
  end
end
