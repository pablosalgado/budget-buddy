class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Set Sentry user context for error tracking
  before_action :set_sentry_context

  private

  def set_sentry_context
    return unless defined?(Sentry)

    # Set user context if user is authenticated
    # Update this when you implement authentication
    # Sentry.set_user(
    #   id: current_user&.id,
    #   email: current_user&.email,
    #   username: current_user&.name
    # )

    # Set request context
    Sentry.set_context(:request_info, {
      remote_ip: request.remote_ip,
      user_agent: request.user_agent,
      request_id: request.request_id
    })
  end
end
