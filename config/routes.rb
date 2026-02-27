Vv::BrowserManager::Engine.routes.draw do
  get "config", to: "config#show", defaults: { format: :json }
end
