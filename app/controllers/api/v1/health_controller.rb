module Api
  module V1
    class HealthController < BaseController
      # GET /api/v1/health
      def show
        health_status = {
          status: "healthy",
          timestamp: Time.current.iso8601,
          version: "1.0.0",
          environment: Rails.env,
          checks: {
            database: database_healthy?,
            cache: cache_healthy?
          }
        }

        render json: health_status, status: :ok
      end

      private

      def database_healthy?
        ActiveRecord::Base.connection.active?
      rescue StandardError
        false
      end

      def cache_healthy?
        Rails.cache.write("health_check", true)
        Rails.cache.read("health_check") == true
      rescue StandardError
        false
      end
    end
  end
end
