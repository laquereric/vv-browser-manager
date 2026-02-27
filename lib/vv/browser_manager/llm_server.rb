module Vv
  module BrowserManager
    class LlmServer
      # Subscribes to LlmRequested events and routes inference to the browser
      # via ActionCable. The browser (vv-plugin or vv-browser JS) handles
      # provider routing and returns the result, which we publish as LlmCompleted.
      #
      # Called by the engine initializer after RES is configured.
      def self.subscribe(event_store)
        event_store.subscribe(
          method(:handle_request),
          to: [Events::LlmRequested]
        )
      end

      def self.handle_request(event)
        correlation_id = event.data[:correlation_id]
        prompt = event.data[:prompt]
        system_prompt = event.data[:system_prompt]

        # Route to browser via ActionCable broadcast
        prefix = Vv::Rails.configuration.channel_prefix
        ActionCable.server.broadcast(
          "#{prefix}:llm:requests",
          {
            event: "llm:request",
            data: {
              correlation_id: correlation_id,
              prompt: prompt,
              system_prompt: system_prompt,
              source: "vv-memory",
            }
          }
        )
      rescue => e
        ::Rails.logger.error("[VvBrowserManager::LlmServer] Error routing LLM request: #{e.message}")
      end

      # Called when the browser returns an inference result.
      # Typically invoked from an EventBus handler for llm:response events.
      def self.complete(correlation_id:, content:, model: nil, tokens: nil)
        event_store = ::Rails.configuration.event_store
        event_store.publish(
          Events::LlmCompleted.new(
            data: {
              correlation_id: correlation_id,
              content: content,
              model: model,
              tokens: tokens,
            },
            metadata: { correlation_id: correlation_id }
          ),
          stream_name: "llm:responses"
        )
      end
    end
  end
end
