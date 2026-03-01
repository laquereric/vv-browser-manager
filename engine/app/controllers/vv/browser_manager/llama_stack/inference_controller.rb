module Vv
  module BrowserManager
    module LlamaStack
      class InferenceController < BaseController
        include ActionController::Live

        # POST /v1/inference/chat-completion
        def chat_completion
          model = params[:model]
          messages = params[:messages]
          stream = params[:stream] == true || params[:stream] == "true"

          return bad_request("model is required") unless model.present?
          return bad_request("messages is required") unless messages.present?

          inference_params = extract_inference_params

          if stream
            stream_chat_completion(model, messages, inference_params)
          else
            result = ProviderClient.chat_completion(
              model: model, messages: messages.map(&:to_unsafe_h), **inference_params
            )
            record_turn(model, messages, result) if turn_model
            render json: result
          end
        rescue ArgumentError => e
          render json: { error: e.message }, status: :bad_request
        rescue => e
          render json: { error: e.message }, status: :internal_server_error
        end

        # POST /v1/inference/completion
        def completion
          model = params[:model]
          content = params[:content] || params[:prompt]
          stream = params[:stream] == true || params[:stream] == "true"

          return bad_request("model is required") unless model.present?
          return bad_request("content or prompt is required") unless content.present?

          inference_params = extract_inference_params

          if stream
            stream_text_completion(model, content, inference_params)
          else
            result = ProviderClient.completion(
              model: model, prompt: content, **inference_params
            )
            render json: result
          end
        rescue ArgumentError => e
          render json: { error: e.message }, status: :bad_request
        rescue => e
          render json: { error: e.message }, status: :internal_server_error
        end

        # POST /v1/inference/embeddings
        def embeddings
          model = params[:model]
          contents = params[:contents] || params[:input]

          return bad_request("model is required") unless model.present?
          return bad_request("contents is required") unless contents.present?

          result = ProviderClient.embeddings(model: model, input: contents)
          render json: result
        rescue ArgumentError => e
          render json: { error: e.message }, status: :bad_request
        rescue => e
          render json: { error: e.message }, status: :internal_server_error
        end

        private

        def stream_chat_completion(model, messages, inference_params)
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

        def stream_text_completion(model, content, inference_params)
          response.headers["Content-Type"] = "text/event-stream"
          response.headers["Cache-Control"] = "no-cache"
          response.headers["Connection"] = "keep-alive"

          ProviderClient.completion(
            model: model,
            prompt: content,
            stream: true,
            **inference_params,
          ) do |chunk|
            response.stream.write("data: #{chunk.to_json}\n\n")
          end
          response.stream.write("data: [DONE]\n\n")
        ensure
          response.stream.close
        end

        def extract_inference_params
          p = {}
          p[:temperature] = params[:temperature].to_f if params[:temperature]
          p[:max_tokens] = params[:max_tokens].to_i if params[:max_tokens]
          p[:top_p] = params[:top_p].to_f if params[:top_p]
          # Llama Stack uses sampling_params as a nested object
          if params[:sampling_params].is_a?(ActionController::Parameters)
            sp = params[:sampling_params]
            p[:temperature] ||= sp[:temperature]&.to_f
            p[:max_tokens] ||= sp[:max_tokens]&.to_i
            p[:top_p] ||= sp[:top_p]&.to_f
          end
          p.compact
        end

        def record_turn(model_name, messages, result)
          return unless turn_model && model_model
          model_record = model_model.find_by(api_model_id: model_name) ||
                         model_model.find_by(name: model_name)
          return unless model_record

          turn_model.create(
            model: model_record,
            message_history: messages,
            request: messages.last&.dig("content"),
            completion: result.dig(:choices, 0, :message, :content),
            input_tokens: result.dig(:usage, :prompt_tokens),
            output_tokens: result.dig(:usage, :completion_tokens),
          )
        rescue => e
          Rails.logger.warn("[LlamaStack] Failed to record turn: #{e.message}")
        end
      end
    end
  end
end
