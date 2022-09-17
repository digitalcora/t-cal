require "http/server/handler"
require "markd"

# HTTP handler that serves the TCal web site at the root path.
class TCal::Handlers::Site
  include HTTP::Handler

  # Creates a handler instance.
  # The `canonical_origin` is used to construct the iCal URL shown on the page.
  def initialize(canonical_origin : String)
    @homepage = Homepage.new(canonical_origin)
  end

  # :nodoc:
  def call(context)
    if context.request.path == "/"
      context.response.content_type = "text/html"
      context.response << @homepage
    else
      call_next(context)
    end
  end

  private class Homepage
    def initialize(canonical_origin : String)
      @content = Content.new(canonical_origin)
    end

    ECR.def_to_s("#{__DIR__}/site/layout.html.ecr")
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
