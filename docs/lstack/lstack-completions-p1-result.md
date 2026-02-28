# Completions (OpenAI-Compatible) — Phase 1 (Core)

API tier: **stable (v1)**
Controller: `llama_stack/completions_controller.rb`

## Endpoints

| Method | Path | Action |
|--------|------|--------|
| POST | `/v1/completions` | Text completion (streaming supported) |

## vv Backend

- ProviderClient dispatches to Ollama (`/api/generate`) or OpenAI (`/v1/completions`)
- Text completion (prompt string, not chat messages)

## Request Format

```json
{
  "model": "meta-llama/Llama-3.2-3B-Instruct",
  "prompt": "Once upon a time",
  "stream": false,
  "max_tokens": 2048,
  "temperature": 0.7,
  "top_p": 0.9,
  "n": 1,
  "stop": null,
  "echo": false
}
```

## Response Format

```json
{
  "id": "cmpl-{uuid}",
  "object": "text_completion",
  "created": 1234567890,
  "model": "meta-llama/Llama-3.2-3B-Instruct",
  "choices": [{
    "text": "...",
    "index": 0,
    "finish_reason": "stop"
  }],
  "usage": { "prompt_tokens": 5, "completion_tokens": 20, "total_tokens": 25 }
}
```

## Dependencies

- ProviderClient with text completion support
- Ollama `/api/generate` endpoint

## Status

- [x] Controller
- [x] Ollama text completion dispatch
- [x] Streaming support
- [x] Verified: controllers load + routes registered in test-host app (2026-02-28)
