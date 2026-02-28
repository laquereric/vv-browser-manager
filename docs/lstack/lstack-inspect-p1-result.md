# Inspect — Phase 1 (Core)

API tier: **stable (v1)**
Controller: `llama_stack/inspect_controller.rb`

## Endpoints

| Method | Path | Action |
|--------|------|--------|
| GET | `/v1/health` | Health check |
| GET | `/v1/version` | Server version |

## vv Backend

- Health: verify DB connection, return status
- Version: return `Vv::BrowserManager::VERSION`

## Response Format (health)

```json
{
  "status": "ok"
}
```

## Response Format (version)

```json
{
  "version": "0.9.7"
}
```

## Dependencies

- None (self-contained)

## Status

- [x] Controller (health)
- [x] Controller (version)
- [x] Verified: controllers load + routes registered in test-host app (2026-02-28)
