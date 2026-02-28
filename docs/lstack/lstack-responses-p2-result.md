# Responses — Phase 2 (Maps to Existing vv Models)

API tier: **stable (v1)**
Controller: `llama_stack/responses_controller.rb`

## Endpoints

| Method | Path | Action |
|--------|------|--------|
| POST | `/v1/responses` | Create response (run inference) |
| GET | `/v1/responses/:response_id` | Retrieve response |
| DELETE | `/v1/responses/:response_id` | Delete response |
| GET | `/v1/responses/:response_id/input_items` | List input items |

## vv Backend

- **Response → Turn**: Maps to host app `Turn` table
- Create response = create Turn with inference dispatch
- `Turn.message_history` = input items snapshot
- `Turn.completion` = output content

## Response Format

```json
{
  "id": "resp-{turn_id}",
  "object": "response",
  "created_at": 1234567890,
  "model": "meta-llama/Llama-3.2-3B-Instruct",
  "output": [{
    "type": "message",
    "role": "assistant",
    "content": [{ "type": "output_text", "text": "..." }]
  }],
  "usage": { "input_tokens": 10, "output_tokens": 20, "total_tokens": 30 },
  "status": "completed"
}
```

## Mapping: vv Turn → Llama Stack Response

| vv Field | Llama Stack Field |
|----------|------------------|
| `turn.id` | `id` (prefixed `resp-`) |
| `turn.model.api_model_id` | `model` |
| `turn.completion` | `output[0].content[0].text` |
| `turn.input_tokens` | `usage.input_tokens` |
| `turn.output_tokens` | `usage.output_tokens` |
| `turn.message_history` | input_items |

## Dependencies

- Host app `Turn`, `Model` tables
- ProviderClient for inference dispatch

## Status

- [x] Controller (create, retrieve, delete, input_items)
- [x] ResponseFormatter: Turn → Response
- [x] Verified: controllers load + migrations pass in test-host app (2026-02-28)
