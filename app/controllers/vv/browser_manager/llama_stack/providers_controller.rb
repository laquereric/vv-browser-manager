module Vv
  module BrowserManager
    module LlamaStack
      class ProvidersController < BaseController
        # GET /v1/providers
        def index
          if provider_model
            records = provider_model.where(active: true)
            render json: ResponseFormatter.provider_list(records)
          else
            render json: ResponseFormatter.provider_list([])
          end
        end

        # GET /v1/providers/:id
        def show
          return not_found("Provider table not available") unless provider_model
          record = provider_model.find_by!(name: params[:id]) rescue
                   provider_model.find_by!(id: params[:id])
          render json: ResponseFormatter.provider(record)
        end
      end
    end
  end
end
