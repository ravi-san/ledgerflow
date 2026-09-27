default_frontend_origins = [
  "http://localhost:5173",
  "http://127.0.0.1:5173"
].freeze

configured_origins = ENV["FRONTEND_ORIGINS"].presence || ENV["FRONTEND_ORIGIN"].presence
frontend_origins = configured_origins ? configured_origins.split(",").map(&:strip).reject(&:blank?) : default_frontend_origins

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*frontend_origins)

    resource "*",
      headers: :any,
      expose: ["Authorization"],
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      max_age: 600
  end
end

# ActionCable performs its own origin check, separate from Rack::Cors.
Rails.application.config.action_cable.allowed_request_origins = frontend_origins
