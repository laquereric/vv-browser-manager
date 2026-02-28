# Scoring Functions — Phase 3

API tier: **stable (v1)**
Controller: `llama_stack/scoring_functions_controller.rb`

## Endpoints

| Method | Path | Action |
|--------|------|--------|
| GET | `/v1/scoring-functions` | List scoring functions |
| GET | `/v1/scoring-functions/:fn_id` | Retrieve scoring function |
| POST | `/v1/scoring-functions` | Register scoring function |
| DELETE | `/v1/scoring-functions/:fn_id` | Delete scoring function |

## vv Backend

- New `vv_llama_scoring_functions` table
- Built-in functions seeded from `Benchmark.score_response` categories

## New Table: `vv_llama_scoring_functions`

| Column | Type | Notes |
|--------|------|-------|
| `id` | string (PK) | Function identifier |
| `description` | text | What this function measures |
| `return_type` | string | "float", "boolean" |
| `params` | json | Function-specific config |
| `provider_id` | string | Optional, for LLM-as-judge |

## Response Format

```json
{
  "identifier": "format_valid",
  "description": "Checks if response is valid JSON or text",
  "return_type": "float",
  "params": {},
  "provider_id": null
}
```

## Status

- [x] Migration
- [x] Model
- [x] Controller (CRUD)
- [ ] Seed built-in functions
- [x] Verified: controllers load + migrations pass in test-host app (2026-02-28)
