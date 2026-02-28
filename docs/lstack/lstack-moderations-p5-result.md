# Moderations — Phase 5 (Batch + Prompts)

API tier: **stable (v1)**
Controller: `llama_stack/moderations_controller.rb`

## Endpoints

| Method | Path | Action |
|--------|------|--------|
| POST | `/v1/moderations` | Moderate content |

## vv Backend

- Delegates to Safety/Shield infrastructure (Phase 3)
- OpenAI-compatible moderation response format
- Uses default shield if none specified

## Request Format

```json
{
  "input": "Content to moderate",
  "model": "llama-guard"
}
```

## Response Format

```json
{
  "id": "modr-{uuid}",
  "model": "llama-guard",
  "results": [{
    "flagged": false,
    "categories": {
      "hate": false,
      "violence": false,
      "self-harm": false,
      "sexual": false
    },
    "category_scores": {
      "hate": 0.001,
      "violence": 0.002,
      "self-harm": 0.0,
      "sexual": 0.001
    }
  }]
}
```

## Dependencies

- Safety/Shields infrastructure (Phase 3)
- ProviderClient for LlamaGuard dispatch

## Status

- [x] Controller
- [x] Delegate to safety infrastructure
- [x] Verified: controllers load + migrations pass in test-host app (2026-02-28)
