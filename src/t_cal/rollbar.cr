require "http/client"
require "json"

class TCal::Rollbar
  enum Kind
    Message
    Trace
  end

  enum Level
    Critical
    Error
    Warning
    Info
    Debug
  end

  def initialize(@log_io : IO, @access_token : String, @environment : String)
  end

  private HEADERS  = HTTP::Headers{"content-type" => "application/json"}
  private ITEM_URL = "https://api.rollbar.com/api/1/item/"

  def error(exception : Exception)
    item = {
      "exception" => {
        "class"   => exception.class.name,
        "message" => exception.message,
      },
      "frames" => Frames.from(exception.backtrace?).reverse,
    }

    send(item: item, kind: Kind::Trace, level: Level::Error)
  end

  def info(body : String, meta : Hash(String, Object))
    item = meta.merge({"body" => body})
    send(item: item, kind: Kind::Message, level: Level::Info)
  end

  private def send(item : Hash(String, Object), kind : Kind, level : Level)
    payload = {
      access_token: @access_token,
      data:         {
        body:        {kind.to_s.downcase => item},
        environment: @environment,
        level:       level.to_s.downcase,
      },
    }.to_json

    HTTP::Client.post(ITEM_URL, HEADERS, payload) do |response|
      if response.status != HTTP::Status::OK
        @log_io.puts "Rollbar error: #{response.body_io.gets_to_end}"
      end
    end
  end

  private module Frames
    # Borrowed from: https://github.com/Sija/raven.cr

    IGNORE_FRAMES      = /_sigtramp|__crystal_(sigfault_handler|raise)|CallStack|caller:|raise<(.+?)>:NoReturn/
    MEMORY_ADDRESS     = /(?<addr>0x[a-f0-9]+)/i
    CALLSTACK_PATTERNS = {
      CRYSTAL_METHOD:          /^(?<file>[^:]+)(?:\:(?<line>\d+)(?:\:(?<col>\d+))?)? in '\*?(?<method>.*?)'(?: at #{MEMORY_ADDRESS})?$/,
      CRYSTAL_PROC:            /^(?<method>~[^@]+)@(?<file>[^:]+)(?:\:(?<line>\d+))(?: at #{MEMORY_ADDRESS})?$/,
      CRYSTAL_CRASH:           /^\[#{MEMORY_ADDRESS}\] \*?(?<method>.*?) \+\d+(?: \((?<times>\d+) times\))?$/,
      CRYSTAL_METHOD_NO_DEBUG: /^(?<method>.+?)$/,
    }

    def self.from(backtrace : Array(String)?)
      initial = [] of Hash(String, Nil | Int32 | String)
      return initial if backtrace.nil?

      backtrace.reduce(initial) do |frames, trace_line|
        next frames if trace_line =~ IGNORE_FRAMES
        next frames if CALLSTACK_PATTERNS.values.none?(&.match(trace_line))

        file = $~["file"]?
        next frames if file.nil? || file.blank?

        method = $~["method"]?
        method = nil if method.try(&.blank?)
        line = $~["line"]?.try(&.to_i?)
        column = $~["col"]?.try(&.to_i?)

        frames << {
          "filename" => file,
          "lineno"   => line,
          "colno"    => column,
          "method"   => method,
        }
      end
    end
  end
end
