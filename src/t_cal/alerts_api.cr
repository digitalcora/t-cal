require "http/client"
require "./v3_api"

module TCal::AlertsAPI
  private URL =
    "https://api-v3.mbta.com/alerts?" + HTTP::Params.encode({
      "filter[route_type]" => "0,1",
      "filter[severity]"   => "5,6,7,8,9,10",
    })

  def self.get!
    HTTP::Client.get(URL) do |response|
      if response.status == HTTP::Status::OK
        V3API::AlertsResponse.from_json(response.body_io).data
      else
        raise "Unexpected response: #{response.body_io.gets_to_end}"
      end
    end
  end
end
