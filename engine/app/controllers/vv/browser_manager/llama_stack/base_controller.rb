module Vv
  module BrowserManager
    module LlamaStack
      class BaseController < ActionController::API
        before_action :authenticate_bearer_token

        rescue_from ActiveRecord::RecordNotFound, with: :not_found
        rescue_from ActionController::ParameterMissing, with: :bad_request

        private

        def authenticate_bearer_token
          # Optional bearer token auth — skip if host app has no ApiToken model
          return unless defined?(::ApiToken)

          token = request.headers["Authorization"]&.sub(/\ABearer\s+/, "")
          return if token.blank? # Allow unauthenticated if no token sent

          unless ::ApiToken.authenticate(token)
            render json: { error: "Invalid or expired token" }, status: :unauthorized
          end
        end

        def not_found(exception = nil)
          msg = exception&.message || "Resource not found"
          render json: { error: msg }, status: :not_found
        end

        def bad_request(exception = nil)
          msg = exception&.message || "Bad request"
          render json: { error: msg }, status: :bad_request
        end

        def unprocessable(msg)
          render json: { error: msg }, status: :unprocessable_entity
        end

        def not_implemented
          render json: { error: "Not implemented" }, status: :not_implemented
        end

        # Helpers for accessing host app models (available in engine context)
        def provider_model
          ::Provider if defined?(::Provider)
        end

        def model_model
          ::Model if defined?(::Model)
        end

        def session_model
          ::Session if defined?(::Session)
        end

        def turn_model
          ::Turn if defined?(::Turn)
        end
      end
    end
  end
end
