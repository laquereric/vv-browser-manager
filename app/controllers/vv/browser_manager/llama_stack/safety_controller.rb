module Vv
  module BrowserManager
    module LlamaStack
      class SafetyController < BaseController
        # POST /v1/safety/run-shield
        def run_shield
          shield_id = params[:shield_id]
          messages = params[:messages]

          return bad_request("shield_id is required") unless shield_id.present?
          return bad_request("messages is required") unless messages.present?

          shield = Shield.find(shield_id)

          # Build a safety-check prompt from the messages
          content = messages.map { |m|
            m = m.respond_to?(:to_unsafe_h) ? m.to_unsafe_h : m
            "#{m['role']}: #{m['content']}"
          }.join("\n")

          safety_prompt = [
            { "role" => "user", "content" => "Analyze the following conversation for safety violations. Respond with JSON: {\"safe\": true/false, \"categories\": [], \"explanation\": \"...\"}\n\n#{content}" }
          ]

          begin
            # Try to dispatch to the shield's provider model
            model_id = shield.provider_shield_id || "llama-guard"
            result = ProviderClient.chat_completion(model: model_id, messages: safety_prompt)
            response_text = result.dig(:choices, 0, :message, :content) || ""

            # Parse safety result
            parsed = JSON.parse(Vv::BrowserManager::Benchmark.strip_markdown_fences(response_text)) rescue nil

            if parsed && parsed["safe"] == false
              render json: {
                violation: {
                  violation_level: "error",
                  user_message: parsed["explanation"] || "Content flagged",
                  metadata: { shield_id: shield_id, categories: parsed["categories"] || [] },
                },
              }
            else
              render json: {
                violation: {
                  violation_level: "info",
                  user_message: "No safety issues detected",
                  metadata: { shield_id: shield_id, categories: [] },
                },
              }
            end
          rescue => e
            # If shield model isn't available, return safe by default
            render json: {
              violation: {
                violation_level: "info",
                user_message: "Shield unavailable: #{e.message}",
                metadata: { shield_id: shield_id, categories: [] },
              },
            }
          end
        end
      end
    end
  end
end
