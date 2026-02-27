module Vv
  module BrowserManager
    class LlmClient
      # Synchronous LLM inference via RES events.
      # Publishes LlmRequested, polls for LlmCompleted.
      # Safe to call from background jobs — no latency constraints.
      #
      # @param prompt [String] the inference prompt
      # @param system_prompt [String] optional system prompt
      # @param stream_name [String] RES stream for correlation (default: "llm:requests")
      # @param timeout [Integer] max seconds to wait for response (default: 60)
      # @return [String, nil] the LLM response content, or nil on timeout
      def self.infer(prompt, system_prompt: nil, stream_name: "llm:requests", timeout: 60)
        event_store = ::Rails.configuration.event_store
        correlation_id = SecureRandom.uuid

        # Publish request
        event_store.publish(
          Events::LlmRequested.new(
            data: {
              prompt: prompt,
              system_prompt: system_prompt,
              correlation_id: correlation_id,
            },
            metadata: { correlation_id: correlation_id }
          ),
          stream_name: stream_name
        )

        # Poll for response (background job context — blocking is fine)
        deadline = Time.current + timeout
        loop do
          response = find_response(event_store, correlation_id)
          return response if response

          return nil if Time.current > deadline
          sleep 0.5
        end
      end

      private

      def self.find_response(event_store, correlation_id)
        # Read recent LlmCompleted events and find our correlation
        events = event_store.read
          .of_type([Events::LlmCompleted])
          .backward
          .limit(50)
          .to_a

        match = events.find { |e| e.data[:correlation_id] == correlation_id }
        match&.data&.dig(:content)
      end
    end
  end
end
