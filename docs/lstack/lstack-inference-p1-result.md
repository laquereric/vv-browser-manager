# Inference — Phase 1 (Core)

API tier: **stable (v1)**
Controller: `llama_stack/inference_controller.rb`

## Endpoints

| Method | Path | Action |
|--------|------|--------|
| POST | `/v1/inference/chat-completion` | Chat completion (streaming supported) |
| POST | `/v1/inference/completion` | Text completion (streaming supported) |
| POST | `/v1/inference/embeddings` | Generate embeddings |

## vv Backend

- ProviderClient dispatches to Ollama (`/api/chat`), OpenAI, or Anthropic
- Reuses `Benchmark.ollama_infer` HTTP pattern
- Resolves model → provider via host app `Model` + `Provider` tables
- Creates `Turn` record for each request/response cycle

## Request Format

```json
{
  "model": "meta-llama/Llama-3.2-3B-Instruct",
  "messages": [{ "role": "user", "content": "Hello" }],
  "stream": false,
  "sampling_params": { "temperature": 0.7 },
  "tools": [],
  "response_format": { "type": "json_object" }
}
```

## Response Format

```json
{
  "id": "chatcmpl-{uuid}",
  "choices": [{
    "index": 0,
    "message": { "role": "assistant", "content": "..." },
    "finish_reason": "stop"
  }],
  "usage": { "prompt_tokens": 10, "completion_tokens": 20, "total_tokens": 30 }
}
```

## Streaming Response (SSE)

```
data: {"id":"chatcmpl-{uuid}","choices":[{"index":0,"delta":{"role":"assistant","content":"Hello"}}]}

data: [DONE]
```

## Dependencies

- Host app `Provider`, `Model` tables
- Net::HTTP for Ollama dispatch
- ActionController::Live for SSE streaming

## Status

- [x] Controller
- [x] ProviderClient Ollama dispatch
- [x] ProviderClient OpenAI dispatch
- [x] ProviderClient Anthropic dispatch
- [x] Streaming support
- [x] Turn recording
- [x] Verified: controllers load + routes registered in test-host app (2026-02-28)
