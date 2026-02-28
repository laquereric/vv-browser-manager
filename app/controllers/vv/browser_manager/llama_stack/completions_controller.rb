module Vv
  module BrowserManager
    module LlamaStack
      class CompletionsController < BaseController
        include ActionController::Live

        # POST /v1/completions
        def create
          model = params[:model]
          prompt = params[:prompt]
          stream = params[:stream] == true || params[:stream] == "true"

          return bad_request("model is required") unless model.present?
          return bad_request("prompt is required") unless prompt.present?

          inference_params = {
            temperature: params[:temperature]&.to_f,
            max_tokens: params[:max_tokens]&.to_i,
            top_p: params[:top_p]&.to_f,
          }.compact

          if stream
            response.headers["Content-Type"] = "text/event-stream"
            response.headers["Cache-Control"] = "no-cache"
            response.headers["Connection"] = "keep-alive"

            ProviderClient.completion(
              model: model, prompt: prompt, stream: true, **inference_params
            ) do |chunk|
              response.stream.write("data: #{chunk.to_json}\n\n")
            end
            response.stream.write("data: [DONE]\n\n")
            response.stream.close
          else
            result = ProviderClient.completion(model: model, prompt: prompt, **inference_params)
            render json: result
          end
        rescue ArgumentError => e
          render json: { error: e.message }, status: :bad_request
        rescue => e
          render json: { error: e.message }, status: :internal_server_error
        end
      end
    end
  end
end
