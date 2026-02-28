module Vv
  module BrowserManager
    module LlamaStack
      class ChatController < BaseController
        include ActionController::Live

        # POST /v1/chat/completions
        def create
          model = params[:model]
          messages = params[:messages]
          stream = params[:stream] == true || params[:stream] == "true"

          return bad_request("model is required") unless model.present?
          return bad_request("messages is required") unless messages.present?

          inference_params = extract_params

          if stream
            stream_response(model, messages, inference_params)
          else
            result = ProviderClient.chat_completion(
              model: model, messages: messages.map(&:to_unsafe_h), **inference_params
            )
            render json: result
          end
        rescue ArgumentError => e
          render json: { error: e.message }, status: :bad_request
        rescue => e
          render json: { error: e.message }, status: :internal_server_error
        end

        # GET /v1/chat/completions/:id
        def show
          return not_found("Turn table not available") unless turn_model
          turn = turn_model.includes(:model).find(params[:id])
          render json: ResponseFormatter.response(turn)
        end

        private

        def stream_response(model, messages, inference_params)
          response.headers["Content-Type"] = "text/event-stream"
          response.headers["Cache-Control"] = "no-cache"
          response.headers["Connection"] = "keep-alive"

          ProviderClient.chat_completion(
            model: model,
            messages: messages.map(&:to_unsafe_h),
            stream: true,
            **inference_params,
          ) do |chunk|
            response.stream.write("data: #{chunk.to_json}\n\n")
          end
          response.stream.write("data: [DONE]\n\n")
        ensure
          response.stream.close
        end

        def extract_params
          p = {}
          p[:temperature] = params[:temperature].to_f if params[:temperature]
          p[:max_tokens] = params[:max_tokens].to_i if params[:max_tokens]
          p[:top_p] = params[:top_p].to_f if params[:top_p]
          p[:n] = params[:n].to_i if params[:n]
          p[:stop] = params[:stop] if params[:stop]
          p.compact
        end
      end
    end
  end
end
