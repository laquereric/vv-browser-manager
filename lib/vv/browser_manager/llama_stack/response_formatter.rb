require "securerandom"

module Vv
  module BrowserManager
    module LlamaStack
      module ResponseFormatter
        # --- Chat Completion (non-streaming) ---

        def self.chat_completion(content:, model:, input_tokens: nil, output_tokens: nil, latency_ms: nil)
          input_tokens ||= 0
          output_tokens ||= 0
          {
            id: "chatcmpl-#{SecureRandom.hex(12)}",
            object: "chat.completion",
            created: Time.now.to_i,
            model: model,
            choices: [{
              index: 0,
              message: { role: "assistant", content: content },
              finish_reason: "stop",
            }],
            usage: {
              prompt_tokens: input_tokens,
              completion_tokens: output_tokens,
              total_tokens: input_tokens + output_tokens,
            },
          }
        end

        # --- Chat Completion Chunk (streaming) ---

        def self.chat_completion_chunk(content:, completion_id:, model:, done: false)
          {
            id: completion_id,
            object: "chat.completion.chunk",
            created: Time.now.to_i,
            model: model,
            choices: [{
              index: 0,
              delta: done ? {} : { role: "assistant", content: content },
              finish_reason: done ? "stop" : nil,
            }],
          }
        end

        # --- Text Completion (non-streaming) ---

        def self.text_completion(text:, model:, input_tokens: nil, output_tokens: nil, latency_ms: nil)
          input_tokens ||= 0
          output_tokens ||= 0
          {
            id: "cmpl-#{SecureRandom.hex(12)}",
            object: "text_completion",
            created: Time.now.to_i,
            model: model,
            choices: [{
              text: text,
              index: 0,
              finish_reason: "stop",
            }],
            usage: {
              prompt_tokens: input_tokens,
              completion_tokens: output_tokens,
              total_tokens: input_tokens + output_tokens,
            },
          }
        end

        # --- Text Completion Chunk (streaming) ---

        def self.text_completion_chunk(text:, completion_id:, model:, done: false)
          {
            id: completion_id,
            object: "text_completion.chunk",
            created: Time.now.to_i,
            model: model,
            choices: [{
              text: done ? "" : text,
              index: 0,
              finish_reason: done ? "stop" : nil,
            }],
          }
        end

        # --- Embeddings ---

        def self.embeddings(embeddings:, model:, input_count: 1)
          data = (embeddings || []).each_with_index.map do |emb, i|
            { object: "embedding", index: i, embedding: emb }
          end
          {
            object: "list",
            data: data,
            model: model,
            usage: { prompt_tokens: input_count, total_tokens: input_count },
          }
        end

        # --- Model ---

        def self.model(record)
          {
            identifier: record.api_model_id,
            provider_id: record.provider&.name&.downcase,
            provider_resource_id: record.api_model_id,
            model_type: "llm",
            metadata: {
              context_window: record.respond_to?(:context_window) ? record.context_window : nil,
              capabilities: record.respond_to?(:capabilities) ? record.capabilities : nil,
            }.compact,
          }
        end

        def self.model_list(records)
          { object: "list", data: records.map { |r| model(r) } }
        end

        # --- Provider ---

        def self.provider(record)
          {
            provider_id: record.name.downcase,
            provider_type: "remote::#{record.name.downcase}",
            config: {
              api_base: record.api_base,
              requires_api_key: record.requires_api_key,
            }.compact,
          }
        end

        def self.provider_list(records)
          { object: "list", data: records.map { |r| provider(r) } }
        end

        # --- Conversation (from Session) ---

        def self.conversation(session)
          {
            conversation_id: session.id.to_s,
            metadata: (session.respond_to?(:metadata) ? session.metadata : {}) || {},
            created_at: session.created_at&.iso8601,
            updated_at: session.updated_at&.iso8601,
          }
        end

        # --- Response (from Turn) ---

        def self.response(turn)
          {
            id: "resp-#{turn.id}",
            object: "response",
            created_at: turn.created_at.to_i,
            model: turn.model&.api_model_id,
            output: [{
              type: "message",
              role: "assistant",
              content: [{ type: "output_text", text: turn.completion }],
            }],
            usage: {
              input_tokens: turn.input_tokens || 0,
              output_tokens: turn.output_tokens || 0,
              total_tokens: (turn.input_tokens || 0) + (turn.output_tokens || 0),
            },
            status: "completed",
          }
        end

        # --- Route ---

        def self.route(path:, method:, description: nil)
          entry = { path: path, method: method }
          entry[:description] = description if description
          entry
        end

        def self.route_list(routes)
          { object: "list", data: routes }
        end

        # --- Generic list wrapper ---

        def self.list(data, has_more: false)
          result = { object: "list", data: data }
          result[:has_more] = has_more if has_more
          result
        end
      end
    end
  end
end
