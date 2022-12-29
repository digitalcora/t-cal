require "http/server/handler"
require "markd"
require "../calendar/html"
require "../date"
require "../v3_api"

# HTTP handler that serves the TCal web site at the root path.
class TCal::Handlers::Site
  include HTTP::Handler

  # Creates a handler instance.
  # The `canonical_origin` is used to construct the iCal URL shown on the page.
  def initialize(@canonical_origin : String)
  end

  # :nodoc:
  def call(context)
    if context.request.path == "/"
      context.response.content_type = "text/html"
      context.response << Homepage.new(
        canonical_origin: @canonical_origin,
        alerts: V3API.calendar_alerts_with_routes,
        today: TCal.now.to_date
      )
    else
      call_next(context)
    end
  end

  private class Homepage
    def initialize(
      canonical_origin : String,
      alerts : V3API::AlertsWithRoutes,
      today : Date
    )
      @calendar = Calendar.new(alerts, today)
      @content = Content.new(canonical_origin)
    end

    ECR.def_to_s("#{__DIR__}/site/layout.html.ecr")
  end

  private class Calendar
    @initial_page : Int32

    def initialize(alerts : V3API::AlertsWithRoutes, @today : Date)
      @months = TCal::Calendar::HTML.new(alerts, today).months
      @initial_page = @months.index! { |month| same_month?(month.start, today) }
    end

    ECR.def_to_s("#{__DIR__}/site/calendar.html.ecr")

    private def same_month?(a : Date, b : Date) : Bool
      # ameba:disable Lint/LiteralsComparison
      {a.year, a.month} == {b.year, b.month}
    end
  end

  private class Content
    def initialize(@canonical_origin : String)
    end

    def to_s(io : IO)
      io <<
        Markd.to_html(
          ECR.render("#{__DIR__}/site/content.md.ecr"),
          Markd::Options.new(smart: true)
        )
    end
  end
end
