# Providers — Phase 1 (Core)

API tier: **stable (v1)**
Controller: `llama_stack/providers_controller.rb`

## Endpoints

| Method | Path | Action |
|--------|------|--------|
| GET | `/v1/providers` | List all providers |
| GET | `/v1/providers/:provider_id` | Retrieve provider |

## vv Backend

- Host app `Provider` table
- Read-only; providers are managed via host app API (`/api/providers`)

## Response Format (list)

```json
{
  "object": "list",
  "data": [
    {
      "provider_id": "ollama",
      "provider_type": "remote::ollama",
      "config": {
        "api_base": "http://localhost:11434",
        "requires_api_key": false
      }
    },
    {
      "provider_id": "openai",
      "provider_type": "remote::openai",
      "config": {
        "api_base": "https://api.openai.com/v1",
        "requires_api_key": true
      }
    }
  ]
}
```

## Mapping: vv Provider → Llama Stack

| vv Field | Llama Stack Field |
|----------|------------------|
| `provider.name.downcase` | `provider_id` |
| `"remote::#{provider.name.downcase}"` | `provider_type` |
| `provider.api_base` | `config.api_base` |
| `provider.requires_api_key` | `config.requires_api_key` |

## Dependencies

- Host app `Provider` table

## Status

- [x] Controller (list)
- [x] Controller (retrieve)
- [x] ResponseFormatter mapping
- [x] Verified: controllers load + routes registered in test-host app (2026-02-28)
