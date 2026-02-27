module Vv
  module BrowserManager
    class Engine < ::Rails::Engine
      isolate_namespace Vv::BrowserManager

      # Auto-include migrations from the engine
      initializer "vv_browser_manager.migrations" do |app|
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end

      initializer "vv_browser_manager.routes" do |app|
        app.routes.append do
          mount Vv::BrowserManager::Engine => "/vv"
        end
      end

      # Subscribe LlmServer to RES events after event_store is configured
      initializer "vv_browser_manager.llm_server", after: :load_config_initializers do
        ActiveSupport.on_load(:after_initialize) do
          if defined?(::Rails.configuration.event_store) && ::Rails.configuration.event_store
            Vv::BrowserManager::LlmServer.subscribe(::Rails.configuration.event_store)
          end
        end
      end
    end
  end
end
