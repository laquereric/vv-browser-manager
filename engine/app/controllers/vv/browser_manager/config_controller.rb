module Vv
  module BrowserManager
    class ConfigController < ActionController::API
      def show
        config = {
          cable_url: Vv::Rails.configuration.cable_url,
          channel: "VvChannel",
          version: Vv::Rails::VERSION,
          prefix: Vv::Rails.configuration.channel_prefix,
        }

        # Include known browser models if any have been discovered
        unless Vv::BrowserManager.model_registry.empty?
          config[:models] = Vv::BrowserManager.model_registry.to_a
        end

        render json: config
      end
    end
  end
end
