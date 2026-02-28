# Shields — Phase 3 (Safety + Scoring)

API tier: **stable (v1)**
Controller: `llama_stack/shields_controller.rb`

## Endpoints

| Method | Path | Action |
|--------|------|--------|
| GET | `/v1/shields` | List shields |
| GET | `/v1/shields/:identifier` | Retrieve shield |
| POST | `/v1/shields` | Register shield |
| DELETE | `/v1/shields/:identifier` | Delete shield |

## vv Backend

- New `vv_llama_shields` table
- Shield = a safety model config (e.g., LlamaGuard)

## New Table: `vv_llama_shields`

| Column | Type | Notes |
|--------|------|-------|
| `id` | string (PK) | Shield identifier |
| `provider_id` | string | Provider for safety checks |
| `provider_shield_id` | string | Provider-specific model |
| `shield_type` | string | e.g., "llama_guard" |
| `params` | json | Shield parameters |

## Response Format

```json
{
  "identifier": "llama-guard",
  "provider_id": "ollama",
  "provider_resource_id": "llama-guard:latest",
  "shield_type": "llama_guard",
  "params": {}
}
```

## Status

- [x] Migration
- [x] Model
- [x] Controller (list, retrieve, register, delete)
- [x] Verified: controllers load + migrations pass in test-host app (2026-02-28)
