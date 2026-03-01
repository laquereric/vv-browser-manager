module Vv
  module BrowserManager
    module LlamaStack
      class InspectController < BaseController
        skip_before_action :authenticate_bearer_token

        # GET /v1/health
        def health
          render json: { status: "ok" }
        end

        # GET /v1/version
        def version
          render json: { version: Vv::BrowserManager::VERSION }
        end
      end
    end
  end
end
