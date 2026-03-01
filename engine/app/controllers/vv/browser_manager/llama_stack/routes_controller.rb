module Vv
  module BrowserManager
    module LlamaStack
      class RoutesController < BaseController
        skip_before_action :authenticate_bearer_token

        # GET /v1/inspect/routes
        def index
          routes = Vv::BrowserManager::LlamaStack::Engine.routes.routes.map do |route|
            path = route.path.spec.to_s.gsub("(.:format)", "")
            verb = route.verb.presence || "GET"
            ResponseFormatter.route(path: path, method: verb)
          end.reject { |r| r[:path].blank? }

          render json: ResponseFormatter.route_list(routes)
        end
      end
    end
  end
end
