# Admin — Phase 6 (Alpha)

API tier: **alpha (v1alpha)**
Controller: `llama_stack/alpha/admin_controller.rb`

## Endpoints

| Method | Path | Action |
|--------|------|--------|
| GET | `/v1alpha/admin/health` | Health check |
| GET | `/v1alpha/admin/version` | Server version |
| GET | `/v1alpha/admin/providers` | List providers |
| GET | `/v1alpha/admin/providers/:provider_id` | Inspect provider |
| GET | `/v1alpha/admin/inspect/routes` | List routes |

## vv Backend

- Health: DB + Ollama connectivity check
- Version: `Vv::BrowserManager::VERSION`
- Providers: Host app `Provider` table with extended details
- Routes: Rails routing introspection (alpha-prefixed)
- Superset of Inspect (v1) with additional admin details

## Response Format (health)

```json
{
  "status": "ok",
  "checks": {
    "database": "ok",
    "ollama": "ok",
    "event_store": "ok"
  }
}
```

## Dependencies

- Host app `Provider` table
- Ollama health check (`/api/tags`)

## Status

- [ ] Controller (health, version, providers, routes)
- [ ] Ollama connectivity check
- [ ] Extended provider inspection
