module Vv
  module BrowserManager
    module LlamaStack
      class FilesController < BaseController
        # GET /v1/files
        def index
          files = LlamaFile.all
          files = files.where(purpose: params[:purpose]) if params[:purpose].present?
          data = files.map { |f| format_file(f) }
          render json: ResponseFormatter.list(data)
        end

        # POST /v1/files
        def create
          file_id = "file_#{SecureRandom.hex(12)}"

          if params[:file].respond_to?(:original_filename)
            # Multipart upload
            uploaded = params[:file]
            storage_dir = Rails.root.join("storage", "llama_files")
            FileUtils.mkdir_p(storage_dir)
            storage_path = storage_dir.join(file_id)
            File.open(storage_path, "wb") { |f| f.write(uploaded.read) }

            record = LlamaFile.create!(
              id: file_id,
              filename: uploaded.original_filename,
              purpose: params[:purpose] || "assistants",
              bytes: File.size(storage_path),
              mime_type: uploaded.content_type,
              storage_path: storage_path.to_s,
              status: "processed",
            )
          else
            # JSON body with content
            record = LlamaFile.create!(
              id: file_id,
              filename: params[:filename] || "unnamed",
              purpose: params[:purpose] || "assistants",
              bytes: params[:content]&.bytesize || 0,
              status: "uploaded",
            )
          end

          render json: format_file(record), status: :created
        end

        # GET /v1/files/:file_id
        def show
          file = LlamaFile.find(params[:file_id])
          render json: format_file(file)
        end

        # DELETE /v1/files/:file_id
        def destroy
          file = LlamaFile.find(params[:file_id])
          File.delete(file.storage_path) if file.storage_path && File.exist?(file.storage_path)
          file.destroy!
          render json: { id: file.id, object: "file", deleted: true }
        end

        # GET /v1/files/:file_id/content
        def content
          file = LlamaFile.find(params[:file_id])
          return not_found("File has no stored content") unless file.storage_path && File.exist?(file.storage_path)

          send_file file.storage_path, type: file.mime_type || "application/octet-stream"
        end

        private

        def format_file(f)
          {
            id: f.id,
            object: "file",
            bytes: f.bytes,
            created_at: f.created_at.to_i,
            filename: f.filename,
            purpose: f.purpose,
            status: f.status,
          }
        end
      end
    end
  end
end
