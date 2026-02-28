# Safety — Phase 3

API tier: **stable (v1)**
Controller: `llama_stack/safety_controller.rb`

## Endpoints

| Method | Path | Action |
|--------|------|--------|
| POST | `/v1/safety/run-shield` | Run safety shield against messages |

## vv Backend

- Looks up shield from `vv_llama_shields`
- Dispatches to LlamaGuard model via ProviderClient
- Parses output for safe/unsafe classification

## Request Format

```json
{
  "shield_id": "llama-guard",
  "messages": [{ "role": "user", "content": "..." }],
  "params": {}
}
```

## Response Format

```json
{
  "violation": {
    "violation_level": "info",
    "user_message": "No safety issues detected",
    "metadata": { "shield_id": "llama-guard", "categories": [] }
  }
}
```

## Dependencies

- `vv_llama_shields` table
- ProviderClient for LlamaGuard dispatch

## Status

- [x] Controller (run-shield)
- [x] LlamaGuard prompt template
- [x] Response parsing
- [x] Verified: controllers load + migrations pass in test-host app (2026-02-28)
