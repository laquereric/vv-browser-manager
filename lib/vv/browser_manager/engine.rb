module Vv
  module BrowserManager
    class Engine < ::Rails::Engine
      isolate_namespace Vv::BrowserManager

      initializer "vv_browser_manager.routes" do |app|
        app.routes.append do
          mount Vv::BrowserManager::Engine => "/vv"
        end
      end
    end
  end
end
