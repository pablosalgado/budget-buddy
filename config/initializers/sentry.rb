# frozen_string_literal: true

# Sentry Error Tracking Configuration
# https://docs.sentry.io/platforms/ruby/guides/rails/

Sentry.init do |config|
  # DSN (Data Source Name) from Sentry project settings
  # Get this from: https://sentry.io/settings/projects/
  config.dsn = ENV["SENTRY_DSN"]

  # Only enable in production (disable in development/test)
  # Change to %w[development production staging] to enable everywhere
  config.enabled_environments = %w[development production staging]

  # Breadcrumbs provide context about what led to an error
  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]

  # Performance monitoring - sample 100% of transactions in production
  # Reduce to 0.1 (10%) for high-traffic apps
  config.traces_sample_rate = 1.0

  # Don't send personally identifiable information (PII) by default
  config.send_default_pii = false

  # Track which deploy/release caused errors
  # Set GIT_COMMIT_SHA in production deployment
  config.release = ENV["GIT_COMMIT_SHA"] if ENV["GIT_COMMIT_SHA"].present?

  # Filter sensitive data from error reports
  config.before_send = lambda do |event, hint|
    # Remove password fields from request data
    if event.request&.data
      event.request.data.delete("password")
      event.request.data.delete("password_confirmation")
      event.request.data.delete("current_password")
      event.request.data.delete("token")
      event.request.data.delete("secret")
    end

    # Remove sensitive headers
    if event.request&.headers
      event.request.headers.delete("Authorization")
      event.request.headers.delete("X-Auth-Token")
    end

    event
  end

  # Customize error grouping
  # config.before_send_transaction = lambda do |event, hint|
  #   # Modify transaction events before sending
  #   event
  # end

  # Ignore certain exceptions that aren't really errors
  config.excluded_exceptions += %w[ActionController::RoutingError ActiveRecord::RecordNotFound]

  # Set environment from RAILS_ENV
  config.environment = Rails.env

  # Set tags using set_tags (correct method for Sentry 6.x)
  Sentry.set_tags(
    app: "budget-buddy",
    server: ENV["HOSTNAME"] || Socket.gethostname
  )
end
