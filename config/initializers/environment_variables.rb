# frozen_string_literal: true

# Environment Variable Validation
# Ensures required environment variables are present in production

if Rails.env.production?
  REQUIRED_ENV_VARS = %w[
    DATABASE_URL
    SECRET_KEY_BASE
    RAILS_ENV
  ].freeze

  missing_vars = REQUIRED_ENV_VARS.reject { |var| ENV[var].present? }

  if missing_vars.any?
    raise "Missing required environment variables: #{missing_vars.join(', ')}\n" \
          "Please set these in your production environment."
  end

  # Validate SECRET_KEY_BASE length (should be at least 64 characters)
  if ENV["SECRET_KEY_BASE"].present? && ENV["SECRET_KEY_BASE"].length < 64
    Rails.logger.warn "SECRET_KEY_BASE is shorter than recommended (64+ characters)"
  end
end

# Optional: Validate that .env file exists in development
if Rails.env.development? && !File.exist?(Rails.root.join(".env"))
  Rails.logger.warn "\n" + "=" * 80
  Rails.logger.warn "⚠️  .env file not found!"
  Rails.logger.warn "Copy .env.example to .env and fill in your local values:"
  Rails.logger.warn "  cp .env.example .env"
  Rails.logger.warn "=" * 80 + "\n"
end
