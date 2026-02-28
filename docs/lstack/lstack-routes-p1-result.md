# Routes — Phase 1 (Core)

API tier: **stable (v1)**
Controller: `llama_stack/routes_controller.rb`

## Endpoints

| Method | Path | Action |
|--------|------|--------|
| GET | `/v1/inspect/routes` | List all mounted routes |

## vv Backend

- Introspect `Rails.application.routes` for `/v1*` paths
- Return as structured list

## Response Format

```json
{
  "object": "list",
  "data": [
    { "path": "/v1/models", "method": "GET", "description": "List models" },
    { "path": "/v1/inference/chat-completion", "method": "POST", "description": "Chat completion" },
    { "path": "/v1/chat/completions", "method": "POST", "description": "OpenAI-compatible chat" }
  ]
}
```

## Dependencies

- Rails routing introspection

## Status

- [x] Controller
- [x] Verified: controllers load + routes registered in test-host app (2026-02-28)
