require "rails_event_store"

module Vv
  module BrowserManager
    module Events
      # Published by LlmClient — request for LLM inference
      LlmRequested = Class.new(RailsEventStore::Event)

      # Published by LlmServer — inference result from browser
      LlmCompleted = Class.new(RailsEventStore::Event)

      ALL = [LlmRequested, LlmCompleted].freeze
    end
  end
end
