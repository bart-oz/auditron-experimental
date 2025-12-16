# frozen_string_literal: true

module Api
  module V1
    class BaseController < ActionController::API
      protected

      def current_user
        @current_api_key&.user
      end

      # Render a successful response with consistent structure
      def render_success(data, status: :ok)
        render json: { success: true, data: }, status:
      end

      # Render an error response with consistent structure
      def render_error(error_code, message: nil, details: nil)
        render json: {
          success: false,
          error: {
            code: error_code.code,
            message: message || error_code.default_message,
            details:
          }.compact
        }, status: error_code.status
      end

      private

      def authenticate_api_key!
        token = extract_token_from_header
        api_key = ApiKey.authenticate(token) if token.present?

        if api_key.present? && !api_key.expired?
          @current_api_key = api_key
          @current_api_key.touch_last_used
        else
          error_code = api_key&.expired? ? ErrorCodes::TOKEN_EXPIRED : ErrorCodes::UNAUTHORIZED
          render_error(error_code)
        end
      end

      def extract_token_from_header
        auth_header = request.headers["Authorization"]
        return nil if auth_header.blank?

        auth_header.gsub(/^Bearer\s+/, "")
      end
    end
  end
end
