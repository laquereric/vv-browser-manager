require "json"
require "net/http"
require "uri"
require "securerandom"

module Vv
  module BrowserManager
    module LlamaStack
      module ProviderClient
        # Chat completion — dispatches to the appropriate provider.
        # When stream: true and a block is given, yields SSE chunks.
        # Returns a Llama Stack formatted response hash.
        def self.chat_completion(model:, messages:, stream: false, **params, &block)
          provider, api_model_id = resolve_model(model)
          raise ArgumentError, "Unknown model: #{model}" unless provider

          case provider_type(provider)
          when :ollama
            ollama_chat(provider, api_model_id, messages, stream: stream, **params, &block)
          when :openai
            openai_chat(provider, api_model_id, messages, stream: stream, **params, &block)
          when :anthropic
            anthropic_chat(provider, api_model_id, messages, stream: stream, **params, &block)
          else
            raise ArgumentError, "Unsupported provider: #{provider.name}"
          end
        end

        # Text completion — prompt string, not chat messages.
        def self.completion(model:, prompt:, stream: false, **params, &block)
          provider, api_model_id = resolve_model(model)
          raise ArgumentError, "Unknown model: #{model}" unless provider

          case provider_type(provider)
          when :ollama
            ollama_generate(provider, api_model_id, prompt, stream: stream, **params, &block)
          else
            # Convert to chat for providers that don't support raw completion
            messages = [{ role: "user", content: prompt }]
            chat_completion(model: model, messages: messages, stream: stream, **params, &block)
          end
        end

        # Embeddings — returns vector arrays.
        def self.embeddings(model:, input:, **params)
          provider, api_model_id = resolve_model(model)
          raise ArgumentError, "Unknown model: #{model}" unless provider

          case provider_type(provider)
          when :ollama
            ollama_embed(provider, api_model_id, input, **params)
          else
            raise ArgumentError, "Embeddings not supported for provider: #{provider.name}"
          end
        end

        # --- Ollama dispatch ---

        def self.ollama_chat(provider, model_id, messages, stream: false, **params, &block)
          uri = URI("#{provider.api_base}/api/chat")

          body = {
            model: model_id,
            messages: normalize_messages(messages),
            stream: stream,
            options: build_ollama_options(params),
          }

          if stream && block
            ollama_stream_request(uri, body, &block)
          else
            start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            data = http_post_json(uri, body, timeout: params[:timeout] || 120)
            elapsed_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).round

            ResponseFormatter.chat_completion(
              content: data.dig("message", "content"),
              model: model_id,
              input_tokens: data["prompt_eval_count"],
              output_tokens: data["eval_count"],
              latency_ms: elapsed_ms,
            )
          end
        end

        def self.ollama_generate(provider, model_id, prompt, stream: false, **params, &block)
          uri = URI("#{provider.api_base}/api/generate")

          body = {
            model: model_id,
            prompt: prompt,
            stream: stream,
            options: build_ollama_options(params),
          }

          if stream && block
            ollama_stream_request(uri, body, format: :completion, &block)
          else
            start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            data = http_post_json(uri, body, timeout: params[:timeout] || 120)
            elapsed_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).round

            ResponseFormatter.text_completion(
              text: data["response"],
              model: model_id,
              input_tokens: data["prompt_eval_count"],
              output_tokens: data["eval_count"],
              latency_ms: elapsed_ms,
            )
          end
        end

        def self.ollama_embed(provider, model_id, input, **params)
          uri = URI("#{provider.api_base}/api/embed")
          input = [input] if input.is_a?(String)

          body = { model: model_id, input: input }
          data = http_post_json(uri, body, timeout: params[:timeout] || 60)

          ResponseFormatter.embeddings(
            embeddings: data["embeddings"],
            model: model_id,
            input_count: input.size,
          )
        end

        # --- OpenAI dispatch ---

        def self.openai_chat(provider, model_id, messages, stream: false, **params, &block)
          uri = URI("#{provider.api_base}/chat/completions")

          body = {
            model: model_id,
            messages: normalize_messages(messages),
            stream: stream,
          }
          body[:temperature] = params[:temperature] if params[:temperature]
          body[:max_tokens] = params[:max_tokens] if params[:max_tokens]
          body[:top_p] = params[:top_p] if params[:top_p]
          body[:n] = params[:n] if params[:n]
          body[:stop] = params[:stop] if params[:stop]

          headers = { "Authorization" => "Bearer #{api_key_for(provider)}" }

          if stream && block
            openai_stream_request(uri, body, headers, &block)
          else
            start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            data = http_post_json(uri, body, timeout: params[:timeout] || 120, headers: headers)
            elapsed_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).round

            # OpenAI already returns the right format; normalize it
            ResponseFormatter.chat_completion(
              content: data.dig("choices", 0, "message", "content"),
              model: model_id,
              input_tokens: data.dig("usage", "prompt_tokens"),
              output_tokens: data.dig("usage", "completion_tokens"),
              latency_ms: elapsed_ms,
            )
          end
        end

        # --- Anthropic dispatch ---

        def self.anthropic_chat(provider, model_id, messages, stream: false, **params, &block)
          uri = URI("#{provider.api_base}/messages")

          # Anthropic uses system as a top-level param, not in messages
          system_msg = nil
          filtered = messages.map { |m| m.transform_keys(&:to_s) }.reject do |m|
            if m["role"] == "system"
              system_msg = m["content"]
              true
            end
          end

          body = {
            model: model_id,
            messages: filtered,
            max_tokens: params[:max_tokens] || 1024,
          }
          body[:system] = system_msg if system_msg
          body[:temperature] = params[:temperature] if params[:temperature]
          body[:top_p] = params[:top_p] if params[:top_p]
          body[:stream] = stream

          headers = {
            "x-api-key" => api_key_for(provider),
            "anthropic-version" => "2023-06-01",
          }

          if stream && block
            anthropic_stream_request(uri, body, headers, &block)
          else
            start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            data = http_post_json(uri, body, timeout: params[:timeout] || 120, headers: headers)
            elapsed_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).round

            content = data.dig("content", 0, "text")
            ResponseFormatter.chat_completion(
              content: content,
              model: model_id,
              input_tokens: data.dig("usage", "input_tokens"),
              output_tokens: data.dig("usage", "output_tokens"),
              latency_ms: elapsed_ms,
            )
          end
        end

        # --- Streaming helpers ---

        def self.ollama_stream_request(uri, body, format: :chat, &block)
          completion_id = "chatcmpl-#{SecureRandom.hex(12)}"
          http = build_http(uri, timeout: 300)
          request = Net::HTTP::Post.new(uri.path, "Content-Type" => "application/json")
          request.body = body.to_json

          http.request(request) do |response|
            response.read_body do |chunk|
              chunk.each_line do |line|
                next if line.strip.empty?
                data = JSON.parse(line) rescue next

                if format == :chat && data.dig("message", "content")
                  block.call(ResponseFormatter.chat_completion_chunk(
                    content: data["message"]["content"],
                    completion_id: completion_id,
                    model: body[:model],
                    done: data["done"],
                  ))
                elsif format == :completion && data["response"]
                  block.call(ResponseFormatter.text_completion_chunk(
                    text: data["response"],
                    completion_id: completion_id,
                    model: body[:model],
                    done: data["done"],
                  ))
                end
              end
            end
          end
        end

        def self.openai_stream_request(uri, body, headers, &block)
          http = build_http(uri, timeout: 300)
          request = Net::HTTP::Post.new(uri.path, { "Content-Type" => "application/json" }.merge(headers))
          request.body = body.to_json

          http.request(request) do |response|
            response.read_body do |chunk|
              chunk.each_line do |line|
                line = line.strip
                next unless line.start_with?("data: ")
                payload = line.sub("data: ", "")
                break if payload == "[DONE]"
                data = JSON.parse(payload) rescue next
                block.call(data)
              end
            end
          end
        end

        def self.anthropic_stream_request(uri, body, headers, &block)
          completion_id = "chatcmpl-#{SecureRandom.hex(12)}"
          http = build_http(uri, timeout: 300)
          request = Net::HTTP::Post.new(uri.path, { "Content-Type" => "application/json" }.merge(headers))
          request.body = body.to_json

          http.request(request) do |response|
            response.read_body do |chunk|
              chunk.each_line do |line|
                line = line.strip
                next unless line.start_with?("data: ")
                data = JSON.parse(line.sub("data: ", "")) rescue next

                if data["type"] == "content_block_delta" && data.dig("delta", "text")
                  block.call(ResponseFormatter.chat_completion_chunk(
                    content: data["delta"]["text"],
                    completion_id: completion_id,
                    model: body[:model],
                  ))
                end
              end
            end
          end
        end

        # --- Internals ---

        def self.resolve_model(model_identifier)
          return [nil, nil] unless defined?(::Model) && defined?(::Provider)

          # Try by api_model_id first, then by name
          record = ::Model.includes(:provider).find_by(api_model_id: model_identifier)
          record ||= ::Model.includes(:provider).find_by(name: model_identifier)
          return [nil, nil] unless record&.provider

          [record.provider, record.api_model_id]
        end

        def self.provider_type(provider)
          name = provider.name.to_s.downcase
          if name.include?("ollama") then :ollama
          elsif name.include?("openai") then :openai
          elsif name.include?("anthropic") then :anthropic
          else :unknown
          end
        end

        def self.api_key_for(provider)
          return nil unless provider.respond_to?(:api_key)
          provider.api_key
        end

        def self.normalize_messages(messages)
          messages.map do |m|
            m = m.transform_keys(&:to_s)
            { "role" => m["role"], "content" => m["content"] }
          end
        end

        def self.build_ollama_options(params)
          opts = {}
          opts[:temperature] = params[:temperature] if params[:temperature]
          opts[:num_predict] = params[:max_tokens] if params[:max_tokens]
          opts[:top_p] = params[:top_p] if params[:top_p]
          opts
        end

        def self.http_post_json(uri, body, timeout: 120, headers: {})
          http = build_http(uri, timeout: timeout)
          request = Net::HTTP::Post.new(uri.path, { "Content-Type" => "application/json" }.merge(headers))
          request.body = body.to_json

          resp = http.request(request)
          unless resp.is_a?(Net::HTTPSuccess)
            raise "HTTP #{resp.code}: #{resp.body}"
          end
          JSON.parse(resp.body)
        end

        def self.build_http(uri, timeout: 120)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = (uri.scheme == "https")
          http.read_timeout = timeout
          http.open_timeout = 10
          http
        end

        private_class_method :resolve_model, :provider_type, :api_key_for,
                             :normalize_messages, :build_ollama_options,
                             :http_post_json, :build_http
      end
    end
  end
end
