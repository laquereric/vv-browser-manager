module Vv
  module BrowserManager
    module LlamaStack
      class BatchesController < BaseController
        # GET /v1/batches
        def index
          batches = Batch.all.order(created_at: :desc)
          data = batches.map { |b| format_batch(b) }
          render json: ResponseFormatter.list(data)
        end

        # POST /v1/batches
        def create
          batch = Batch.create!(
            id: "batch_#{SecureRandom.hex(12)}",
            input_file_id: params[:input_file_id],
            endpoint: params[:endpoint],
            status: "validating",
            metadata: params[:metadata] || {},
          )

          # TODO: Enqueue background job to process the batch
          batch.update!(status: "in_progress")

          render json: format_batch(batch), status: :created
        end

        # GET /v1/batches/:batch_id
        def show
          batch = Batch.find(params[:batch_id])
          render json: format_batch(batch)
        end

        # POST /v1/batches/:batch_id/cancel
        def cancel
          batch = Batch.find(params[:batch_id])
          batch.update!(status: "cancelled")
          render json: format_batch(batch)
        end

        private

        def format_batch(b)
          {
            id: b.id,
            object: "batch",
            endpoint: b.endpoint,
            input_file_id: b.input_file_id,
            status: b.status,
            output_file_id: b.output_file_id,
            error_file_id: b.error_file_id,
            request_counts: b.request_counts || {},
            metadata: b.metadata || {},
            created_at: b.created_at.to_i,
            completed_at: b.completed_at&.to_i,
          }
        end
      end
    end
  end
end
