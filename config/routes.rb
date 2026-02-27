Vv::BrowserManager::Engine.routes.draw do
  get "config", to: "config#show", defaults: { format: :json }
  get "models", to: "models#index", defaults: { format: :json }
  post "models/discover", to: "models#discover", defaults: { format: :json }
end
