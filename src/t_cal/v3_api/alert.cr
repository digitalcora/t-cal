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
    getter created_at : Time
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

    # Tries to guess whether this alert is "transient" (represents an unplanned
    # disruption that is not expected to last very long).
    #
    # An alert is transient if it has only one active period, with a start time
    # within 1 hour of the alert's creation timestamp, a definite end time, and
    # a duration of less than 12 hours. These are indicators that the alert was
    # likely created in response to a short-term unplanned disruption which was
    # already happening at the time of creation.
    def transient? : Bool
      active_periods.size == 1 &&
        !active_periods[0].end.nil? &&
        (created_at - active_periods[0].start).abs <= 1.hour &&
        active_periods[0].end.not_nil! - active_periods[0].start < 12.hours
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
