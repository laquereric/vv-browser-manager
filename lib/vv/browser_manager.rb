require_relative "browser_manager/version"
require_relative "browser_manager/events"
require_relative "browser_manager/model_registry"
require_relative "browser_manager/model_discovery"
require_relative "browser_manager/precharge_client"
require_relative "browser_manager/llm_client"
require_relative "browser_manager/llm_server"
require_relative "browser_manager/benchmark"
require_relative "browser_manager/engine"

module Vv
  module BrowserManager
    class << self
      def model_registry
        @model_registry ||= ModelRegistry.new
      end
    end
  end
end
