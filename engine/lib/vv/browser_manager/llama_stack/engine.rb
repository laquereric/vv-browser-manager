module Vv
  module BrowserManager
    module LlamaStack
      GEM_ROOT = File.expand_path("../../../..", __dir__)

      # Append Llama Stack routes to the host app via the parent engine
      module Routes
        def self.draw(app)
          routes_file = File.join(GEM_ROOT, "config", "llama_stack_routes.rb")
          return unless File.exist?(routes_file)

          app.routes.append do
            instance_eval(File.read(routes_file), routes_file, 1)
          end
        end
      end
    end
  end
end
