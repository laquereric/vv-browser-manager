# Batches — Phase 5 (Batch + Prompts)

API tier: **stable (v1)**
Controller: `llama_stack/batches_controller.rb`

## Endpoints

| Method | Path | Action |
|--------|------|--------|
| POST | `/v1/batches` | Create batch |
| GET | `/v1/batches/:batch_id` | Retrieve batch |
| POST | `/v1/batches/:batch_id/cancel` | Cancel batch |
| GET | `/v1/batches` | List batches |

## vv Backend

- New `vv_llama_batches` table
- Background job queue (ActiveJob) for batch processing
- Each batch = N inference requests processed asynchronously

## New Table: `vv_llama_batches`

| Column | Type | Notes |
|--------|------|-------|
| `id` | string (PK) | Batch identifier |
| `input_file_id` | string (FK) | Input JSONL file |
| `endpoint` | string | Target endpoint (e.g., "/v1/chat/completions") |
| `status` | string | validating, in_progress, completed, failed, cancelled |
| `output_file_id` | string | Result file (when done) |
| `error_file_id` | string | Error file (when done) |
| `request_counts` | json | { total, completed, failed } |
| `metadata` | json | |

## Response Format

```json
{
  "id": "batch_abc123",
  "object": "batch",
  "endpoint": "/v1/chat/completions",
  "input_file_id": "file_abc",
  "status": "completed",
  "output_file_id": "file_def",
  "request_counts": { "total": 10, "completed": 10, "failed": 0 },
  "created_at": 1234567890,
  "completed_at": 1234567900
}
```

## Dependencies

- Migration
- ActiveJob for async processing
- Files infrastructure (Phase 4)

## Status

- [x] Migration
- [x] Model
- [x] Controller (create, retrieve, cancel, list)
- [ ] Background job (stub)
- [x] Verified: controllers load + migrations pass in test-host app (2026-02-28)
