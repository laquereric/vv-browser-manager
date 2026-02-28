# Embeddings (OpenAI-Compatible) — Phase 1 (Core)

API tier: **stable (v1)**
Controller: `llama_stack/embeddings_controller.rb`

## Endpoints

| Method | Path | Action |
|--------|------|--------|
| POST | `/v1/embeddings` | Generate embeddings |

## vv Backend

- Forward to Ollama `/api/embed` or OpenAI `/v1/embeddings`
- Supports string or array input

## Request Format

```json
{
  "model": "nomic-ai/nomic-embed-text-v1.5",
  "input": ["Hello", "world"],
  "encoding_format": "float",
  "dimensions": 384
}
```

## Response Format

```json
{
  "object": "list",
  "data": [
    { "object": "embedding", "index": 0, "embedding": [0.123, -0.456, ...] },
    { "object": "embedding", "index": 1, "embedding": [0.789, -0.012, ...] }
  ],
  "model": "nomic-ai/nomic-embed-text-v1.5",
  "usage": { "prompt_tokens": 5, "total_tokens": 5 }
}
```

## Dependencies

- ProviderClient with embedding support
- Ollama `/api/embed` endpoint

## Status

- [x] Controller
- [x] Ollama embedding dispatch
- [ ] OpenAI embedding dispatch
- [x] Verified: controllers load + routes registered in test-host app (2026-02-28)
