# Rack::Attack configuration for rate limiting

class Rack::Attack
  ### Configure Cache ###
  # Use Rails cache for rack-attack
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  ### Throttle Spammy Clients ###

  # Throttle all requests by IP (60rpm)
  throttle('req/ip', limit: 60, period: 1.minute) do |req|
    req.ip
  end

  # Throttle POST requests to /api/* to 10 per minute per IP
  throttle('api-posts/ip', limit: 10, period: 1.minute) do |req|
    req.ip if req.post? && req.path.start_with?('/api/')
  end

  # Throttle API requests by API key
  throttle('api-key', limit: 300, period: 5.minutes) do |req|
    req.get_header('X-API-Key') if req.path.start_with?('/api/')
  end

  ### Custom Throttle Response ###
  self.throttled_responder = lambda do |_env|
    [
      429,
      { 'Content-Type' => 'application/json' },
      [{ error: 'Rate limit exceeded. Try again later.' }.to_json]
    ]
  end
end
