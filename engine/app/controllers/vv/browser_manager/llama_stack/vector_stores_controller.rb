module Vv
  module BrowserManager
    module LlamaStack
      class VectorStoresController < BaseController
        # GET /v1/vector_stores
        def index
          stores = VectorStore.all
          data = stores.map { |s| format_store(s) }
          render json: ResponseFormatter.list(data)
        end

        # POST /v1/vector_stores
        def create
          store = VectorStore.create!(
            id: "vs_#{SecureRandom.hex(12)}",
            name: params[:name],
            embedding_model: params[:embedding_model],
            embedding_dimension: params[:embedding_dimension],
            chunking_strategy: params[:chunking_strategy],
            metadata: params[:metadata] || {},
          )
          render json: format_store(store), status: :created
        end

        # GET /v1/vector_stores/:vector_store_id
        def show
          store = VectorStore.find(params[:vector_store_id])
          render json: format_store(store)
        end

        # POST /v1/vector_stores/:vector_store_id/update
        def update
          store = VectorStore.find(params[:vector_store_id])
          store.update!(
            name: params[:name] || store.name,
            metadata: params[:metadata] || store.metadata,
          )
          render json: format_store(store)
        end

        # DELETE /v1/vector_stores/:vector_store_id
        def destroy
          store = VectorStore.find(params[:vector_store_id])
          store.destroy!
          render json: { status: "ok" }
        end

        # POST /v1/vector_stores/:vector_store_id/search
        def search
          store = VectorStore.find(params[:vector_store_id])
          query = params[:query]
          max_results = (params[:max_num_results] || 10).to_i

          return bad_request("query is required") unless query.present?

          # TODO: Implement actual vector search with embeddings
          render json: ResponseFormatter.list([])
        end

        private

        def format_store(s)
          {
            id: s.id,
            object: "vector_store",
            name: s.name,
            status: s.status,
            usage_bytes: s.usage_bytes,
            file_counts: s.file_counts || {},
            metadata: s.metadata || {},
            created_at: s.created_at.to_i,
            expires_at: s.expires_at&.to_i,
          }
        end
      end
    end
  end
end
