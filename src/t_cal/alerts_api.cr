require "http/client"
require "./v3_api"

# Fetches the MBTA Alerts used to generate the TCal calendar.
module TCal::AlertsAPI
  private URL =
    "https://api-v3.mbta.com/alerts?" + HTTP::Params.encode({
      "filter[route_type]" => "0,1",
      "filter[severity]"   => "5,6,7,8,9,10",
    })

  # Fetches the alerts.
  # On a non-200 response, throws an exception containing the response body.
  def self.get! : Array(V3API::Alert)
    HTTP::Client.get(URL) do |response|
      if response.status == HTTP::Status::OK
        V3API::AlertsResponse.from_json(response.body_io).data
      else
        raise "Unexpected response: #{response.body_io.gets_to_end}"
      end
    end
  end
end
