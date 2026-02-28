# Models — Phase 1 (Core)

API tier: **stable (v1)**
Controller: `llama_stack/models_controller.rb`

## Endpoints

| Method | Path | Action |
|--------|------|--------|
| GET | `/v1/models` | List all models |
| GET | `/v1/models/:model_id` | Retrieve model |
| POST | `/v1/models` | Register model |
| DELETE | `/v1/models/:model_id` | Unregister model |

## vv Backend

- Host app `Model` table (belongs_to `Provider`)
- Engine `ModelRegistry` for browser-discovered models
- Register = create Model record in host DB
- Unregister = soft-delete or destroy Model record

## Response Format (list)

```json
{
  "object": "list",
  "data": [
    {
      "identifier": "meta-llama/Llama-3.2-3B-Instruct",
      "provider_id": "ollama",
      "provider_resource_id": "llama3.2:3b-instruct",
      "model_type": "llm",
      "metadata": {
        "context_window": 131072,
        "capabilities": ["chat", "completion"]
      }
    }
  ]
}
```

## Response Format (single)

```json
{
  "identifier": "meta-llama/Llama-3.2-3B-Instruct",
  "provider_id": "ollama",
  "provider_resource_id": "llama3.2:3b-instruct",
  "model_type": "llm",
  "metadata": {
    "context_window": 131072,
    "capabilities": ["chat", "completion"]
  }
}
```

## Mapping: vv Model → Llama Stack

| vv Field | Llama Stack Field |
|----------|------------------|
| `model.api_model_id` | `identifier` |
| `model.provider.name.downcase` | `provider_id` |
| `model.api_model_id` | `provider_resource_id` |
| `"llm"` | `model_type` |
| `model.context_window` | `metadata.context_window` |
| `model.capabilities` | `metadata.capabilities` |

## Dependencies

- Host app `Model`, `Provider` tables
- Engine `ModelRegistry` (for browser models)

## Status

- [x] Controller (list)
- [x] Controller (retrieve)
- [x] Controller (register)
- [x] Controller (unregister)
- [x] ResponseFormatter mapping
- [x] Verified: controllers load + routes registered in test-host app (2026-02-28)
