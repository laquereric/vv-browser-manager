module Vv
  module BrowserManager
    module LlamaStack
      class EmbeddingsController < BaseController
        # POST /v1/embeddings
        def create
          model = params[:model]
          input = params[:input]

          return bad_request("model is required") unless model.present?
          return bad_request("input is required") unless input.present?

          result = ProviderClient.embeddings(model: model, input: input)
          render json: result
        rescue ArgumentError => e
          render json: { error: e.message }, status: :bad_request
        rescue => e
          render json: { error: e.message }, status: :internal_server_error
        end
      end
    end
  end
end
