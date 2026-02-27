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

      # Published by PrechargeClient — request to warm up a model
      PrechargeRequested = Class.new(RailsEventStore::Event)

      # Published when browser completes precharge (model warm)
      PrechargeCompleted = Class.new(RailsEventStore::Event)

      ALL = [LlmRequested, LlmCompleted, ModelDiscoveryRequested, ModelsDiscovered,
             PrechargeRequested, PrechargeCompleted].freeze
    end
  end
end
