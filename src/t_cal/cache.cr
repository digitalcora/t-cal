require "memory_cache"
require "tasker"

# Refinement of `MemoryCache` with additional behaviors.
class TCal::Cache(K, V) < MemoryCache(K, V)
  # Creates a cache.
  #
  # * `expires_in` will be the expiration of every cache entry; `#fetch` and
  #   `#write` are overridden to no longer accept this.
  # * If `clean_every` is non-nil, starts a background task that runs `#cleanup`
  #   on this interval.
  # * If `log` is non-nil, the background task emits an info log indicating how
  #   many entries were cleaned, when greater than zero.
  def initialize(
    @expires_in : Time::Span,
    @clean_every : Time::Span? = nil,
    @log : Log? = nil,
  )
    super()

    if !clean_every.nil?
      Tasker.every(clean_every) do
        count = self.cleanup

        if count > 0 && !log.nil?
          log.info &.emit("Cache cleaned", count: count)
        end
      end
    end
  end

  def fetch(key : K, &block : -> V) : V
    super(key, expires_in: @expires_in, &block)
  end

  def write(key : K, value : V) : V
    super(key, value, expires_in: @expires_in)
  end
end
