# frozen_string_literal: true

# CORS configuration for API access from frontend applications
# Configure allowed origins via CORS_ORIGINS environment variable
# Example: CORS_ORIGINS=http://localhost:3001,https://app.example.com

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # In development/test, allow localhost; in production, use ENV
    origins(*cors_origins)

    resource "/api/*",
             headers: :any,
             methods: %i[get post put patch delete options head],
             credentials: true,
             max_age: 86_400
  end
end

def cors_origins
  if Rails.env.production?
    ENV.fetch("CORS_ORIGINS", "").split(",").map(&:strip)
  else
    ["http://localhost:3000", "http://localhost:3001", "http://127.0.0.1:3000"]
  end
end
