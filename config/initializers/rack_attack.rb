# frozen_string_literal: true

# Rate limiting configuration using Rack::Attack
# Protects API from abuse and ensures fair usage
class Rack::Attack
  Rack::Attack.cache.store = Rails.cache

  throttle("req/ip", limit: 100, period: 1.minute, &:ip)

  self.throttled_responder = lambda do |_request|
    [
      429,
      {
        "Content-Type" => "application/json",
        "Retry-After" => "60"
      },
      [{
        success: false,
        error: {
          code: "RATE_LIMITED",
          message: "Too many requests. Please try again later."
        }
      }.to_json]
    ]
  end
end

Rails.application.config.middleware.use Rack::Attack unless Rails.env.test?
