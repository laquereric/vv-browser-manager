module Vv
  module BrowserManager
    module LlamaStack
      class ScoringFunctionsController < BaseController
        # GET /v1/scoring-functions
        def index
          fns = ScoringFunction.all
          data = fns.map { |f| format_fn(f) }
          render json: ResponseFormatter.list(data)
        end

        # GET /v1/scoring-functions/:id
        def show
          fn = ScoringFunction.find(params[:id])
          render json: format_fn(fn)
        end

        # POST /v1/scoring-functions
        def create
          fn = ScoringFunction.create!(
            id: params[:identifier] || params[:scoring_fn_id],
            description: params[:description],
            return_type: params[:return_type] || "float",
            params: params[:params] || {},
            provider_id: params[:provider_id],
          )
          render json: format_fn(fn), status: :created
        end

        # DELETE /v1/scoring-functions/:id
        def destroy
          fn = ScoringFunction.find(params[:id])
          fn.destroy!
          render json: { status: "ok" }
        end

        private

        def format_fn(fn)
          {
            identifier: fn.id,
            description: fn.description,
            return_type: fn.return_type,
            params: fn.params || {},
            provider_id: fn.provider_id,
          }
        end
      end
    end
  end
end
