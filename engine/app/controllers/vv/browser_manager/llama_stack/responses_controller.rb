module Vv
  module BrowserManager
    module LlamaStack
      class ResponsesController < BaseController
        include ActionController::Live

        # POST /v1/responses
        def create
          return unprocessable("Turn table not available") unless turn_model

          model_name = params[:model]
          input = params[:input]
          stream = params[:stream] == true || params[:stream] == "true"

          return bad_request("model is required") unless model_name.present?
          return bad_request("input is required") unless input.present?

          # Build messages from input (string or array of items)
          messages = build_messages(input)

          if stream
            stream_response(model_name, messages)
          else
            result = ProviderClient.chat_completion(model: model_name, messages: messages)
            turn = create_turn(model_name, messages, result)
            render json: ResponseFormatter.response(turn)
          end
        rescue ArgumentError => e
          render json: { error: e.message }, status: :bad_request
        rescue => e
          render json: { error: e.message }, status: :internal_server_error
        end

        # GET /v1/responses/:response_id
        def show
          turn = find_turn!
          render json: ResponseFormatter.response(turn)
        end

        # DELETE /v1/responses/:response_id
        def destroy
          turn = find_turn!
          turn.destroy!
          render json: { status: "ok" }
        end

        # GET /v1/responses/:response_id/input_items
        def input_items
          turn = find_turn!
          history = turn.message_history || []

          data = history.each_with_index.map do |msg, i|
            msg = msg.transform_keys(&:to_s)
            {
              item_id: "msg-#{turn.id}-#{i}",
              type: "message",
              role: msg["role"] || "user",
              content: [{ type: "input_text", text: msg["content"] || "" }],
            }
          end

          render json: ResponseFormatter.list(data)
        end

        private

        def find_turn!
          raise ActiveRecord::RecordNotFound, "Turn table not available" unless turn_model
          # Strip "resp-" prefix if present
          id = params[:response_id].to_s.sub(/\Aresp-/, "")
          turn_model.includes(:model).find(id)
        end

        def build_messages(input)
          case input
          when String
            [{ "role" => "user", "content" => input }]
          when Array
            input.map do |item|
              item = item.respond_to?(:to_unsafe_h) ? item.to_unsafe_h.stringify_keys : item.stringify_keys
              { "role" => item["role"] || "user", "content" => item["content"] || item["text"] || "" }
            end
          else
            [{ "role" => "user", "content" => input.to_s }]
          end
        end

        def create_turn(model_name, messages, result)
          model_record = model_model&.find_by(api_model_id: model_name) ||
                         model_model&.find_by(name: model_name)

          turn_model.create!(
            model: model_record,
            message_history: messages,
            request: messages.last&.dig("content"),
            completion: result.dig(:choices, 0, :message, :content),
            input_tokens: result.dig(:usage, :prompt_tokens),
            output_tokens: result.dig(:usage, :completion_tokens),
          )
        end

        def stream_response(model_name, messages)
          response.headers["Content-Type"] = "text/event-stream"
          response.headers["Cache-Control"] = "no-cache"
          response.headers["Connection"] = "keep-alive"

          ProviderClient.chat_completion(
            model: model_name,
            messages: messages,
            stream: true,
          ) do |chunk|
            response.stream.write("data: #{chunk.to_json}\n\n")
          end
          response.stream.write("data: [DONE]\n\n")
        ensure
          response.stream.close
        end
      end
    end
  end
end
