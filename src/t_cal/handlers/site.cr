require "cache"
require "http/server/handler"
require "markd"
require "../calendar/html"
require "../date"

# HTTP handler that serves the TCal web site at the root path.
class TCal::Handlers::Site
  include HTTP::Handler

  # Creates a handler instance.
  # The `canonical_origin` is used to construct the iCal URL shown on the page.
  def initialize(@canonical_origin : String)
    @cache = Cache::MemoryStore(String, String)
      .new(expires_in: 1.minute, compress: false)
  end

  # :nodoc:
  def call(context)
    if context.request.path == "/"
      today = TCal.now.to_date

      homepage = @cache.fetch("page-#{today.hash}") do
        Homepage.new(canonical_origin: @canonical_origin, today: today).to_s
      end

      context.response.content_type = "text/html"
      context.response << homepage
    else
      call_next(context)
    end
  end

  private class Homepage
    def initialize(canonical_origin : String, today : Date)
      @calendar = Calendar.new(today)
      @content = Content.new(canonical_origin)
    end

    ECR.def_to_s("#{__DIR__}/site/layout.html.ecr")
  end

  private class Calendar
    @initial_page : Int32

    def initialize(@today : Date)
      @months = TCal::Calendar::HTML.new(today).months
      @initial_page = @months.index! { |month| same_month?(month.start, today) }
    end

    ECR.def_to_s("#{__DIR__}/site/calendar.html.ecr")

    private def same_month?(a : Date, b : Date) : Bool
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
