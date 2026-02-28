module Vv
  module BrowserManager
    module LlamaStack
      class VectorStoreFilesController < BaseController
        before_action :find_store

        # GET /v1/vector_stores/:vector_store_id/files
        def index
          files = @store.vector_store_files
          data = files.map { |f| format_vs_file(f) }
          render json: ResponseFormatter.list(data)
        end

        # POST /v1/vector_stores/:vector_store_id/files
        def create
          vs_file = VectorStoreFile.create!(
            id: "vsf_#{SecureRandom.hex(12)}",
            vector_store_id: @store.id,
            file_id: params[:file_id],
            status: "in_progress",
            chunking_strategy: params[:chunking_strategy],
          )
          render json: format_vs_file(vs_file), status: :created
        end

        # GET /v1/vector_stores/:vector_store_id/files/:file_id
        def show
          vs_file = @store.vector_store_files.find(params[:file_id])
          render json: format_vs_file(vs_file)
        end

        # POST /v1/vector_stores/:vector_store_id/files/:file_id/update
        def update
          vs_file = @store.vector_store_files.find(params[:file_id])
          vs_file.update!(chunking_strategy: params[:chunking_strategy]) if params[:chunking_strategy]
          render json: format_vs_file(vs_file)
        end

        # DELETE /v1/vector_stores/:vector_store_id/files/:file_id
        def destroy
          vs_file = @store.vector_store_files.find(params[:file_id])
          vs_file.destroy!
          render json: { status: "ok" }
        end

        # GET /v1/vector_stores/:vector_store_id/files/:file_id/content
        def content
          vs_file = @store.vector_store_files.find(params[:file_id])
          llama_file = LlamaFile.find_by(id: vs_file.file_id)
          return not_found("File content not available") unless llama_file&.storage_path

          if File.exist?(llama_file.storage_path)
            send_file llama_file.storage_path, type: llama_file.mime_type || "application/octet-stream"
          else
            not_found("File not found on disk")
          end
        end

        private

        def find_store
          @store = VectorStore.find(params[:vector_store_id])
        end

        def format_vs_file(f)
          {
            id: f.id,
            object: "vector_store.file",
            vector_store_id: f.vector_store_id,
            file_id: f.file_id,
            status: f.status,
            chunking_strategy: f.chunking_strategy,
            created_at: f.created_at.to_i,
          }
        end
      end
    end
  end
end
