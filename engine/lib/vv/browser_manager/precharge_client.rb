module Vv
  module BrowserManager
    class PrechargeClient
      PrechargeResult = Struct.new(:status, :model_id, :category, :context_tokens,
                                   :load_time_ms, :prefill_time_ms, :error, keyword_init: true) do
        def ready?       = status == "ready"
        def failed?      = status == "failed"
        def already_warm? = status == "already_warm"
      end

      # Precharge a model with context (non-blocking, returns immediately).
      # Publishes PrechargeRequested → ActionCable → browser loads model + processes context.
      #
      # @param model_id [String] model identifier from ModelRegistry
      # @param category [String] "mcl" or "ollama"
      # @param context [Array<Hash>] messages to pre-process [{role:, content:}]
      # @param priority [String] "high", "normal", or "low"
      # @return [String] correlation_id for tracking
      def self.precharge(model_id:, category: nil, context: [], priority: "normal")
        category ||= resolve_category(model_id)
        event_store = ::Rails.configuration.event_store
        correlation_id = SecureRandom.uuid

        event_store.publish(
          Events::PrechargeRequested.new(
            data: {
              correlation_id: correlation_id,
              model_id: model_id,
              category: category,
              context: context,
              priority: priority,
            },
            metadata: { correlation_id: correlation_id }
          ),
          stream_name: "precharge:requests"
        )

        correlation_id
      end

      # Precharge and block until ready (for sequential workflows).
      #
      # @param model_id [String] model identifier
      # @param category [String] "mcl" or "ollama"
      # @param context [Array<Hash>] messages to pre-process
      # @param timeout [Integer] max seconds to wait
      # @return [PrechargeResult, nil] result or nil on timeout
      def self.precharge_and_wait(model_id:, category: nil, context: [], timeout: 30)
        correlation_id = precharge(model_id: model_id, category: category, context: context)
        event_store = ::Rails.configuration.event_store

        deadline = Time.current + timeout
        loop do
          result = find_result(event_store, correlation_id)
          return result if result

          return nil if Time.current > deadline
          sleep 0.5
        end
      end

      # Check if a model is already precharged.
      #
      # @param model_id [String] model identifier
      # @return [Boolean]
      def self.warm?(model_id:)
        Vv::BrowserManager.model_registry.status(model_id) == :precharged
      end

      # Called when the browser completes a precharge request.
      # Typically invoked from an EventBus handler for precharge:complete events.
      #
      # @param correlation_id [String]
      # @param model_id [String]
      # @param category [String]
      # @param status [String] "ready", "failed", or "already_warm"
      # @param context_tokens [Integer, nil]
      # @param load_time_ms [Integer, nil]
      # @param prefill_time_ms [Integer, nil]
      # @param error [String, nil]
      def self.complete(correlation_id:, model_id:, category: nil, status: "ready",
                        context_tokens: nil, load_time_ms: nil, prefill_time_ms: nil, error: nil)
        # Update registry state
        if status == "ready" || status == "already_warm"
          Vv::BrowserManager.model_registry.update_status(model_id, :precharged)
        end

        # Publish to RES for audit trail and polling
        event_store = ::Rails.configuration.event_store
        event_store.publish(
          Events::PrechargeCompleted.new(
            data: {
              correlation_id: correlation_id,
              model_id: model_id,
              category: category,
              status: status,
              context_tokens: context_tokens,
              load_time_ms: load_time_ms,
              prefill_time_ms: prefill_time_ms,
              error: error,
            },
            metadata: { correlation_id: correlation_id }
          ),
          stream_name: "precharge:responses"
        )
      end

      private

      def self.resolve_category(model_id)
        entry = Vv::BrowserManager.model_registry.find(model_id)
        entry&.category || "unknown"
      end

      def self.find_result(event_store, correlation_id)
        events = event_store.read
          .of_type([Events::PrechargeCompleted])
          .backward
          .limit(50)
          .to_a

        match = events.find { |e| e.data[:correlation_id] == correlation_id }
        return nil unless match

        PrechargeResult.new(
          status: match.data[:status],
          model_id: match.data[:model_id],
          category: match.data[:category],
          context_tokens: match.data[:context_tokens],
          load_time_ms: match.data[:load_time_ms],
          prefill_time_ms: match.data[:prefill_time_ms],
          error: match.data[:error]
        )
      end
    end
  end
end
