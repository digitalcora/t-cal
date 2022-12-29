module TCal
  # The MBTA runs on Eastern Time.
  TZ = Time::Location.load("America/New_York")

  # Returns the current instant in the MBTA's time zone.
  def self.now : Time
    Time.local(TZ)
  end
end
