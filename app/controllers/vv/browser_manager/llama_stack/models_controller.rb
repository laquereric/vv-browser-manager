module Vv
  module BrowserManager
    module LlamaStack
      class ModelsController < BaseController
        # GET /v1/models
        def index
          if model_model
            records = model_model.where(active: true).includes(:provider)
            render json: ResponseFormatter.model_list(records)
          else
            render json: ResponseFormatter.model_list([])
          end
        end

        # GET /v1/models/:id
        def show
          record = find_model!(params[:id])
          render json: ResponseFormatter.model(record)
        end

        # POST /v1/models
        def create
          unless model_model && provider_model
            return unprocessable("Model registration requires host app Model and Provider tables")
          end

          provider = provider_model.find_by!(name: params[:provider_id]) rescue
                     provider_model.find_by(id: params[:provider_id])
          return not_found("Provider not found: #{params[:provider_id]}") unless provider

          record = model_model.create!(
            provider: provider,
            name: params[:identifier] || params[:model_id],
            api_model_id: params[:identifier] || params[:model_id],
            active: true,
          )
          render json: ResponseFormatter.model(record), status: :created
        end

        # DELETE /v1/models/:id
        def destroy
          record = find_model!(params[:id])
          record.destroy!
          render json: { status: "ok" }
        end

        private

        def find_model!(identifier)
          raise ActiveRecord::RecordNotFound, "Model table not available" unless model_model
          model_model.includes(:provider).find_by!(api_model_id: identifier)
        rescue ActiveRecord::RecordNotFound
          model_model.includes(:provider).find_by!(name: identifier)
        end
      end
    end
  end
end
