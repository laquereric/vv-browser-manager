# Chat (OpenAI-Compatible) — Phase 1 (Core)

API tier: **stable (v1)**
Controller: `llama_stack/chat_controller.rb`

## Endpoints

| Method | Path | Action |
|--------|------|--------|
| POST | `/v1/chat/completions` | Create chat completion (streaming supported) |
| GET | `/v1/chat/completions/:id` | Retrieve completion |

## vv Backend

- Same ProviderClient dispatch as Inference, but OpenAI response format
- Stores result as `Turn` record; GET retrieves by Turn ID

## Request Format

```json
{
  "model": "meta-llama/Llama-3.2-3B-Instruct",
  "messages": [{ "role": "user", "content": "Hello" }],
  "stream": false,
  "temperature": 0.7,
  "top_p": 0.9,
  "max_tokens": 2048,
  "n": 1,
  "stop": null,
  "presence_penalty": 0.0,
  "frequency_penalty": 0.0,
  "tools": [],
  "tool_choice": "auto",
  "response_format": { "type": "json_object" },
  "seed": 42
}
```

## Response Format

```json
{
  "id": "chatcmpl-{uuid}",
  "object": "chat.completion",
  "created": 1234567890,
  "model": "meta-llama/Llama-3.2-3B-Instruct",
  "choices": [{
    "index": 0,
    "message": { "role": "assistant", "content": "..." },
    "finish_reason": "stop"
  }],
  "usage": { "prompt_tokens": 10, "completion_tokens": 20, "total_tokens": 30 }
}
```

## Dependencies

- ProviderClient (shared with Inference)
- Host app `Turn` table for retrieval

## Status

- [x] Controller (create)
- [x] Controller (retrieve)
- [x] Streaming support
- [ ] Turn persistence
- [x] Verified: controllers load + routes registered in test-host app (2026-02-28)
