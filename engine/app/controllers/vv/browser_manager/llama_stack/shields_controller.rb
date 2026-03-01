module Vv
  module BrowserManager
    module LlamaStack
      class ShieldsController < BaseController
        # GET /v1/shields
        def index
          shields = Shield.all
          data = shields.map { |s| format_shield(s) }
          render json: ResponseFormatter.list(data)
        end

        # GET /v1/shields/:identifier
        def show
          shield = Shield.find(params[:identifier])
          render json: format_shield(shield)
        end

        # POST /v1/shields
        def create
          shield = Shield.create!(
            id: params[:shield_id] || params[:identifier],
            provider_id: params[:provider_id],
            provider_shield_id: params[:provider_resource_id] || params[:provider_shield_id],
            shield_type: params[:shield_type] || "generic",
            params: params[:params] || {},
          )
          render json: format_shield(shield), status: :created
        end

        # DELETE /v1/shields/:identifier
        def destroy
          shield = Shield.find(params[:identifier])
          shield.destroy!
          render json: { status: "ok" }
        end

        private

        def format_shield(shield)
          {
            identifier: shield.id,
            provider_id: shield.provider_id,
            provider_resource_id: shield.provider_shield_id,
            shield_type: shield.shield_type,
            params: shield.params || {},
          }
        end
      end
    end
  end
end
