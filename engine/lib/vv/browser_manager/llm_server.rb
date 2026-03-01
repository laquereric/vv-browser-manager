module Vv
  module BrowserManager
    class LlmServer
      # Subscribes to LlmRequested and PrechargeRequested events, routing both
      # to the browser via ActionCable. The browser handles provider routing
      # and returns results, which we publish as LlmCompleted/PrechargeCompleted.
      #
      # Called by the engine initializer after RES is configured.
      def self.subscribe(event_store)
        event_store.subscribe(
          method(:handle_request),
          to: [Events::LlmRequested]
        )
        event_store.subscribe(
          method(:handle_precharge),
          to: [Events::PrechargeRequested]
        )
      end

      def self.handle_request(event)
        correlation_id = event.data[:correlation_id]
        prompt = event.data[:prompt]
        system_prompt = event.data[:system_prompt]

        # Mark model as active if we know which one
        model_id = event.data[:model_id]
        Vv::BrowserManager.model_registry.update_status(model_id, :active) if model_id

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

      def self.handle_precharge(event)
        correlation_id = event.data[:correlation_id]
        model_id = event.data[:model_id]
        category = event.data[:category]
        context = event.data[:context]
        priority = event.data[:priority]

        # Route to browser via ActionCable broadcast
        prefix = Vv::Rails.configuration.channel_prefix
        ActionCable.server.broadcast(
          "#{prefix}:precharge:requests",
          {
            event: "precharge:request",
            data: {
              correlation_id: correlation_id,
              model_id: model_id,
              category: category,
              context: context,
              priority: priority,
            }
          }
        )
      rescue => e
        ::Rails.logger.error("[VvBrowserManager::LlmServer] Error routing precharge request: #{e.message}")
      end

      # Called when the browser returns an inference result.
      # Typically invoked from an EventBus handler for llm:response events.
      def self.complete(correlation_id:, content:, model: nil, tokens: nil)
        # Model returns to precharged state (warm with updated context)
        if model
          Vv::BrowserManager.model_registry.update_status(model, :precharged)
        end

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
