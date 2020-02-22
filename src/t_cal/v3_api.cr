require "json"
require "./period"

# Contains structs for loading JSON data from the MBTA's V3 API.
# See also the [API reference](https://api-v3.mbta.com/docs/swagger/index.html).
module TCal::V3API
  # The JSON:API document returned from the Alerts endpoint.
  struct AlertsResponse
    include JSON::Serializable

    getter data : Array(Alert)
  end

  # An Alert resource.
  struct Alert
    include JSON::Serializable

    getter id : String
    getter attributes : AlertAttributes
    forward_missing_to @attributes
  end

  # The attributes of an `Alert` resource.
  #
  # The `active_period` attribute is remapped to `active_periods` to align with
  # the convention that collections have plural names.
  struct AlertAttributes
    include JSON::Serializable

    @[JSON::Field(key: "active_period")]
    getter active_periods : Array(ActivePeriod)
    getter effect : String
    getter header : String
    getter service_effect : String
    getter updated_at : Time
    getter url : String?

    # Returns the `active_periods` that have defined end times.
    def definite_active_periods : Array(TimePeriod)
      active_periods
        .select { |period| !period.end.nil? }
        .map { |period| TimePeriod.new(period.start, period.end.not_nil!) }
    end
  end

  # An item in `AlertAttributes#active_periods`.
  struct ActivePeriod
    include JSON::Serializable

    @start : Time
    @end : Time?

    # Since we do some adjusting of times, we need a time zone rather than the
    # UTC offset provided by ISO8601. We can assume times published by the MBTA
    # are in Eastern time.
    private TZ = Time::Location.load("America/New_York")

    def start
      @start.in(TZ)
    end

    def end
      @end.try(&.in(TZ))
    end
  end
end
