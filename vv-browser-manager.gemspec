require_relative "lib/vv/browser_manager/version"

Gem::Specification.new do |spec|
  spec.name        = "vv-browser-manager"
  spec.version     = Vv::BrowserManager::VERSION
  spec.authors     = ["Vv"]
  spec.summary     = "Browser plugin discovery and management for Vv Rails apps"
  spec.description = "Provides the /vv/config.json discovery endpoint and browser-side module delivery. Works with vv-plugin (Chrome extension) or standalone as a fallback runtime."
  spec.homepage    = "https://github.com/laquereric/vv-browser-manager"
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.files = Dir[
    "lib/**/*",
    "app/**/*",
    "config/**/*",
    "vv-browser-manager.gemspec",
  ]

  spec.add_dependency "railties",          ">= 7.0", "< 9"
  spec.add_dependency "actioncable",       ">= 7.0", "< 9"
  spec.add_dependency "rails_event_store", ">= 2.0", "< 3"
  spec.add_dependency "vv-rails",          ">= 0.9.0", "< 2"
end
