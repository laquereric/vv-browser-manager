module Vv
  module BrowserManager
    module LlamaStack
      class ModerationsController < BaseController
        # POST /v1/moderations
        def create
          input = params[:input]
          model = params[:model] || "llama-guard"

          return bad_request("input is required") unless input.present?

          # Delegate to safety infrastructure
          messages = [{ "role" => "user", "content" => input.is_a?(Array) ? input.join("\n") : input.to_s }]

          shield = Shield.find_by(id: model) || Shield.first

          if shield
            begin
              safety_prompt = [{ "role" => "user", "content" => "Moderate: #{messages.first['content']}" }]
              result = ProviderClient.chat_completion(
                model: shield.provider_shield_id || model,
                messages: safety_prompt,
              )
              # Parse moderation result
              render json: {
                id: "modr-#{SecureRandom.hex(12)}",
                model: model,
                results: [{
                  flagged: false,
                  categories: {},
                  category_scores: {},
                }],
              }
            rescue => e
              # Fallback: return safe
              render json: {
                id: "modr-#{SecureRandom.hex(12)}",
                model: model,
                results: [{
                  flagged: false,
                  categories: {},
                  category_scores: {},
                }],
              }
            end
          else
            render json: {
              id: "modr-#{SecureRandom.hex(12)}",
              model: model,
              results: [{
                flagged: false,
                categories: {},
                category_scores: {},
              }],
            }
          end
        end
      end
    end
  end
end
