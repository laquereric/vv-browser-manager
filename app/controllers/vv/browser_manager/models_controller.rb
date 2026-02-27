module Vv
  module BrowserManager
    class ModelsController < ActionController::API
      # GET /vv/models.json
      # Returns all browser-reported models from the in-memory registry.
      def index
        models = Vv::BrowserManager.model_registry.to_a
        render json: {
          models: models,
          categories: Vv::BrowserManager.model_registry.categories,
        }
      end

      # POST /vv/models/discover.json
      # Triggers model discovery — asks the browser to report available models.
      def discover
        category = params[:category] # optional: "mcl", "ollama", or nil for all
        correlation_id = ModelDiscovery.request(category: category)
        render json: { correlation_id: correlation_id, status: "requested" }
      end
    end
  end
end
