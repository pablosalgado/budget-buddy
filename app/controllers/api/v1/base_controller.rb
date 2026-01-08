module Api
  module V1
    class BaseController < ActionController::API
      # Set Sentry context for API requests
      before_action :set_sentry_context

      # Common API error handling
      rescue_from ActiveRecord::RecordNotFound do |e|
        render json: { error: e.message }, status: :not_found
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      rescue_from ActionController::ParameterMissing do |e|
        render json: { error: e.message }, status: :bad_request
      end

      # Add authentication/authorization hooks here as needed
      # before_action :authenticate_user!
      # before_action :authorize_user!

      private

      def set_sentry_context
        return unless defined?(Sentry)

        # Set user context when authentication is implemented
        # Sentry.set_user(
        #   id: current_user&.id,
        #   email: current_user&.email
        # )

        # Set API-specific context
        Sentry.set_context(:api, {
          version: "v1",
          endpoint: "#{controller_name}##{action_name}",
          request_id: request.request_id
        })
      end

      # Example pagination helper
      def paginate(collection, per_page: 25)
        collection.page(params[:page]).per(per_page)
      end
    end
  end
end
