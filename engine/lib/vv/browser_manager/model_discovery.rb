module Vv
  module BrowserManager
    class ModelDiscovery
      # Request that the browser report its available models.
      # Publishes ModelDiscoveryRequested → ActionCable → browser.
      # Browser responds with model:discovery:report → EventBus handler
      # calls ModelDiscovery.report → publishes ModelsDiscovered to RES
      # and updates ModelRegistry.
      #
      # @param category [String, nil] optional — "mcl", "ollama", or nil for all
      # @return [String] correlation_id for tracking
      def self.request(category: nil)
        event_store = ::Rails.configuration.event_store
        correlation_id = SecureRandom.uuid

        event_store.publish(
          Events::ModelDiscoveryRequested.new(
            data: {
              correlation_id: correlation_id,
              category: category,
            },
            metadata: { correlation_id: correlation_id }
          ),
          stream_name: "models:discovery"
        )

        # Broadcast to browser via ActionCable
        prefix = Vv::Rails.configuration.channel_prefix
        ActionCable.server.broadcast(
          "#{prefix}:models:discovery",
          {
            event: "model:discovery:request",
            data: {
              correlation_id: correlation_id,
              category: category,
            }
          }
        )

        correlation_id
      end

      # Request and wait for browser to report models.
      # @param category [String, nil] optional filter
      # @param timeout [Integer] seconds to wait
      # @return [Array<Hash>, nil] array of model hashes, or nil on timeout
      def self.request_and_wait(category: nil, timeout: 10)
        event_store = ::Rails.configuration.event_store
        correlation_id = request(category: category)

        deadline = Time.current + timeout
        loop do
          events = event_store.read
            .of_type([Events::ModelsDiscovered])
            .backward
            .limit(20)
            .to_a

          match = events.find { |e| e.data[:correlation_id] == correlation_id }
          return match.data[:models] if match

          return nil if Time.current > deadline
          sleep 0.5
        end
      end

      # Called when browser reports available models (via EventBus handler).
      # Updates ModelRegistry and publishes ModelsDiscovered to RES.
      #
      # @param correlation_id [String] from the original request
      # @param category [String] "mcl" or "ollama"
      # @param models [Array<Hash>] each with :model_id, :name, :capabilities, :context_window
      def self.report(correlation_id:, category:, models:)
        # Update in-memory registry
        Vv::BrowserManager.model_registry.register(category: category, models: models)

        # Publish to RES for audit trail and subscribers
        event_store = ::Rails.configuration.event_store
        event_store.publish(
          Events::ModelsDiscovered.new(
            data: {
              correlation_id: correlation_id,
              category: category,
              models: models,
              discovered_at: Time.current.iso8601,
            },
            metadata: { correlation_id: correlation_id }
          ),
          stream_name: "models:discovery"
        )
      rescue => e
        ::Rails.logger.error("[VvBrowserManager::ModelDiscovery] Error reporting models: #{e.message}")
      end

      # Subscribe to ModelDiscoveryRequested events (called by engine initializer).
      def self.subscribe(event_store)
        # ModelDiscoveryRequested is handled by request() which already broadcasts
        # via ActionCable. No additional subscription needed — the browser reports
        # back through EventBus → report().
      end
    end
  end
end
