class WdsImageCache
  attr_accessor :wds_server, :cache_duration

  delegate :logger, to: ::Rails

  def initialize(wds_server, cache_duration: 180.minutes)
    self.wds_server = wds_server
    self.cache_duration = cache_duration
  end

  def cache(key, &block)
    cached_value = read(key)
    return cached_value if cached_value
    return unless block_given?

    uncached_value = get_uncached_value(&block)
    write(key, uncached_value)
    uncached_value
  end

  def delete(key)
    Rails.cache.delete(cache_key + key.to_s)
  end

  def read(key)
    Rails.cache.read(cache_key + key.to_s, cache_options)
  end

  def write(key, value)
    Rails.cache.write(cache_key + key.to_s, value, cache_options)
  end

  def refresh
    Rails.cache.delete(cache_scope_key)
    true
  rescue StandardError => e
    logger.exception('Failed to refresh the WDS image cache', e)
    false
  end

  def cache_scope
    Rails.cache.fetch(cache_scope_key, cache_options) { Foreman.uuid }
  end

  private

  def get_uncached_value(&block)
    return unless block_given?
    wds_server.instance_eval(&block)
  end

  def cache_key
    "wds_server_#{wds_server.id}-#{cache_scope}/"
  end

  def cache_scope_key
    "wds_server_#{wds_server.id}-cache_scope_key"
  end

  def cache_options
    {
      expires_in: cache_duration,
      race_condition_ttl: 1.minute
    }
  end
end
