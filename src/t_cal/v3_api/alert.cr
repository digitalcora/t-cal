require "json"
require "../period"

module TCal::V3API::Alert
  V3API.def_endpoint("/alerts", Resource)

  # An Alert resource.
  struct Resource
    include JSON::Serializable

    getter id : String
    getter attributes : Attributes
    forward_missing_to @attributes
  end

  # The attributes of an Alert resource.
  #
  # The `active_period` and `informed_entity` attributes are remapped to align
  # with the convention that collections have plural names.
  struct Attributes
    include JSON::Serializable

    @[JSON::Field(key: "active_period")]
    getter active_periods : Array(ActivePeriod)
    getter effect : String
    getter header : String
    @[JSON::Field(key: "informed_entity")]
    getter informed_entities : Array(InformedEntity)
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

  # An item in `Attributes#active_periods`.
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

  # An item in `Attributes#informed_entities`.
  struct InformedEntity
    include JSON::Serializable

    getter route : String?
  end
end
