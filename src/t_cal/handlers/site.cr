require "http/server/handler"
require "markd"

# HTTP handler that serves the TCal web site at the root path.
class TCal::Handlers::Site
  include HTTP::Handler

  @content : String

  # Creates a handler instance.
  def initialize
    content = {{read_file "#{__DIR__}/../site/content.md"}}
    options = Markd::Options.new(smart: true)
    @content = Markd.to_html(content, options)
  end

  # :nodoc:
  def call(context)
    if context.request.path == "/"
      context.response.content_type = "text/html"
      ECR.embed("#{__DIR__}/../site/template.ecr", context.response)
    else
      call_next(context)
    end
  end
end
