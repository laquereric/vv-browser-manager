require "monitor"

module Vv
  module BrowserManager
    # In-memory registry of models reported by the browser.
    # Browser sends model:discovery:report via ActionCable → EventBus handler
    # calls ModelRegistry.register → publishes ModelsDiscovered to RES.
    #
    # Thread-safe via Monitor.
    class ModelRegistry
      include MonitorMixin

      Entry = Struct.new(:model_id, :category, :name, :capabilities, :context_window,
                         :status, :last_seen, :metadata, keyword_init: true) do
        def pretrained? = status == :pretrained
        def precharged? = status == :precharged
        def active?     = status == :active
        def available?  = %i[pretrained precharged].include?(status)
      end

      def initialize
        super() # MonitorMixin
        @models = {}
      end

      # Register models reported by the browser.
      # Replaces all models for the given category (full snapshot).
      def register(category:, models:)
        synchronize do
          # Remove stale models for this category
          @models.delete_if { |_, entry| entry.category == category.to_s }

          # Add new ones
          models.each do |m|
            id = m[:model_id] || m["model_id"]
            next unless id

            @models[id] = Entry.new(
              model_id: id,
              category: category.to_s,
              name: m[:name] || m["name"] || id,
              capabilities: m[:capabilities] || m["capabilities"] || {},
              context_window: m[:context_window] || m["context_window"],
              status: :pretrained,
              last_seen: Time.current,
              metadata: m[:metadata] || m["metadata"] || {}
            )
          end
        end
      end

      # Update a single model's lifecycle state.
      def update_status(model_id, status)
        synchronize do
          entry = @models[model_id]
          return unless entry
          entry.status = status.to_sym
          entry.last_seen = Time.current
        end
      end

      # Query methods

      def all
        synchronize { @models.values.dup }
      end

      def by_category(category)
        synchronize { @models.values.select { |e| e.category == category.to_s } }
      end

      def find(model_id)
        synchronize { @models[model_id]&.dup }
      end

      def status(model_id)
        synchronize { @models[model_id]&.status }
      end

      def available
        synchronize { @models.values.select(&:available?) }
      end

      def precharged_models
        synchronize { @models.values.select(&:precharged?) }
      end

      def categories
        synchronize { @models.values.map(&:category).uniq }
      end

      def empty?
        synchronize { @models.empty? }
      end

      def size
        synchronize { @models.size }
      end

      def clear!
        synchronize { @models.clear }
      end

      def to_a
        synchronize do
          @models.values.map do |e|
            { model_id: e.model_id, category: e.category, name: e.name,
              capabilities: e.capabilities, context_window: e.context_window,
              status: e.status, last_seen: e.last_seen }
          end
        end
      end
    end
  end
end
