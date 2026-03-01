module Vv
  module BrowserManager
    module LlamaStack
      class VectorStoreFileBatchesController < BaseController
        # POST /v1/vector_stores/:vector_store_id/file_batches
        def create
          store = VectorStore.find(params[:vector_store_id])
          file_ids = params[:file_ids] || []

          batch_id = "vsfb_#{SecureRandom.hex(12)}"
          created = file_ids.map do |fid|
            VectorStoreFile.create!(
              id: "vsf_#{SecureRandom.hex(12)}",
              vector_store_id: store.id,
              file_id: fid,
              status: "in_progress",
            )
          end

          render json: {
            id: batch_id,
            object: "vector_store.file_batch",
            vector_store_id: store.id,
            status: "in_progress",
            file_counts: { total: created.size, in_progress: created.size, completed: 0, failed: 0, cancelled: 0 },
            created_at: Time.now.to_i,
          }, status: :created
        end

        # GET /v1/vector_stores/:vector_store_id/file_batches/:batch_id
        def show
          render json: { id: params[:batch_id], object: "vector_store.file_batch", status: "completed" }
        end

        # POST /v1/vector_stores/:vector_store_id/file_batches/:batch_id/cancel
        def cancel
          render json: { id: params[:batch_id], status: "cancelled" }
        end

        # GET /v1/vector_stores/:vector_store_id/file_batches/:batch_id/files
        def files
          store = VectorStore.find(params[:vector_store_id])
          data = store.vector_store_files.map do |f|
            { id: f.id, file_id: f.file_id, status: f.status }
          end
          render json: ResponseFormatter.list(data)
        end
      end
    end
  end
end
