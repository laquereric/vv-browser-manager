# Vector Stores — Phase 4 (Tools + RAG)

API tier: **stable (v1)**
Controller: `llama_stack/vector_stores_controller.rb` + nested controllers

## Endpoints

| Method | Path | Action |
|--------|------|--------|
| GET | `/v1/vector_stores` | List stores |
| POST | `/v1/vector_stores` | Create store |
| GET | `/v1/vector_stores/:id` | Retrieve store |
| POST | `/v1/vector_stores/:id` | Update store |
| DELETE | `/v1/vector_stores/:id` | Delete store |
| POST | `/v1/vector_stores/:id/search` | Search store |
| GET | `/v1/vector_stores/:id/files` | List files |
| POST | `/v1/vector_stores/:id/files` | Add file |
| GET | `/v1/vector_stores/:id/files/:file_id` | Retrieve file |
| POST | `/v1/vector_stores/:id/files/:file_id` | Update file |
| DELETE | `/v1/vector_stores/:id/files/:file_id` | Delete file |
| GET | `/v1/vector_stores/:id/files/:file_id/content` | Get content |
| POST | `/v1/vector_stores/:id/file_batches` | Create batch |
| GET | `/v1/vector_stores/:id/file_batches/:batch_id` | Retrieve batch |
| POST | `/v1/vector_stores/:id/file_batches/:batch_id/cancel` | Cancel batch |
| GET | `/v1/vector_stores/:id/file_batches/:batch_id/files` | List batch files |

## vv Backend

- New `vv_llama_vector_stores` and `vv_llama_vector_store_files` tables
- Ollama embeddings via `/api/embed` for vectorization
- Cosine similarity search on stored embeddings

## New Tables

### `vv_llama_vector_stores`

| Column | Type | Notes |
|--------|------|-------|
| `id` | string (PK) | Store identifier |
| `name` | string | Display name |
| `embedding_model` | string | Model for embeddings |
| `embedding_dimension` | integer | Vector dimension |
| `chunking_strategy` | json | Chunk config |
| `metadata` | json | |
| `file_counts` | json | Status counts |
| `expires_at` | datetime | Optional expiry |

### `vv_llama_vector_store_files`

| Column | Type | Notes |
|--------|------|-------|
| `id` | string (PK) | File identifier |
| `vector_store_id` | string (FK) | Parent store |
| `file_id` | string (FK) | Uploaded file ref |
| `status` | string | in_progress, completed, failed |
| `chunking_strategy` | json | Per-file override |
| `embeddings` | binary | Serialized vectors |

## Response Format (store)

```json
{
  "id": "vs_abc123",
  "object": "vector_store",
  "name": "Knowledge Base",
  "status": "completed",
  "usage_bytes": 12345,
  "file_counts": { "in_progress": 0, "completed": 5, "failed": 0, "cancelled": 0, "total": 5 },
  "metadata": {}
}
```

## Response Format (search)

```json
{
  "object": "list",
  "data": [
    { "file_id": "file_abc", "filename": "doc.pdf", "score": 0.95, "content": [{ "type": "text", "text": "..." }] }
  ]
}
```

## Dependencies

- Migrations for 2 tables
- Ollama `/api/embed` for vectorization
- Cosine similarity implementation

## Status

- [x] Migrations
- [x] Models
- [x] Controller (CRUD)
- [ ] Search with cosine similarity (stub -- returns empty)
- [x] Files sub-controller
- [x] File batches sub-controller
- [ ] Embedding generation via Ollama
- [x] Verified: controllers load + migrations pass in test-host app (2026-02-28)
