require "rails_event_store"

module Vv
  module BrowserManager
    module Events
      # Published by LlmClient — request for LLM inference
      LlmRequested = Class.new(RailsEventStore::Event)

      # Published by LlmServer — inference result from browser
      LlmCompleted = Class.new(RailsEventStore::Event)

      # Published by server — ask browser to report available models
      ModelDiscoveryRequested = Class.new(RailsEventStore::Event)

      # Published when browser reports its available models
      ModelsDiscovered = Class.new(RailsEventStore::Event)

      ALL = [LlmRequested, LlmCompleted, ModelDiscoveryRequested, ModelsDiscovered].freeze
    end
  end
end
