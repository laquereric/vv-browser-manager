# vv-browser-manager

Browser plugin discovery and management for Vv Rails apps.

Provides a rich interface to vv-plugin or, for users who do not have the plugin installed, provides an alternative way to get many vv-plugin features.

## What it does

- **`GET /vv/config.json`** — Discovery endpoint for the Vv browser plugin (returns cable_url, channel name, version, prefix)
- **Browser module delivery** — (planned) Serves the 10 Vv JS modules via Rails asset pipeline as a fallback for users without the Chrome extension

## Installation

Add to your Gemfile:

```ruby
gem "vv-browser-manager", path: "vendor/vv-browser-manager"
```

The engine auto-mounts at `/vv`. No additional configuration needed — reads settings from `Vv::Rails.configure`.

## Dependencies

- `vv-rails` (>= 0.9.0) — provides Configuration, VvChannel, EventBus, Events
