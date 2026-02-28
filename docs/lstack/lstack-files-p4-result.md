# Files — Phase 4 (Tools + RAG)

API tier: **stable (v1)**
Controller: `llama_stack/files_controller.rb`

## Endpoints

| Method | Path | Action |
|--------|------|--------|
| GET | `/v1/files` | List files |
| POST | `/v1/files` | Upload file (multipart) |
| GET | `/v1/files/:file_id` | Retrieve file metadata |
| DELETE | `/v1/files/:file_id` | Delete file |
| GET | `/v1/files/:file_id/content` | Get file content |

## vv Backend

- New `vv_llama_files` table
- ActiveStorage or filesystem for binary storage
- Supports purposes: "assistants", "fine-tune"

## New Table: `vv_llama_files`

| Column | Type | Notes |
|--------|------|-------|
| `id` | string (PK) | File identifier |
| `filename` | string | Original filename |
| `purpose` | string | "assistants" or "fine-tune" |
| `bytes` | integer | File size |
| `mime_type` | string | Content type |
| `storage_path` | string | Path on disk or ActiveStorage key |
| `status` | string | uploaded, processed, error |

## Response Format

```json
{
  "id": "file_abc123",
  "object": "file",
  "bytes": 12345,
  "created_at": 1234567890,
  "filename": "data.jsonl",
  "purpose": "assistants",
  "status": "processed"
}
```

## Dependencies

- Migration
- ActiveStorage or filesystem storage

## Status

- [x] Migration
- [x] Model
- [x] Controller (list, upload, retrieve, delete, content)
- [x] File storage backend (filesystem)
- [x] Verified: controllers load + migrations pass in test-host app (2026-02-28)
