# File Processors — Phase 6 (Alpha)

API tier: **alpha (v1alpha)**
Controller: `llama_stack/alpha/file_processors_controller.rb`

## Endpoints

| Method | Path | Action |
|--------|------|--------|
| POST | `/v1alpha/file-processors/process` | Process a file |

## vv Backend

- Takes an uploaded file and extracts/transforms content
- Delegates to appropriate processor (text, PDF, CSV, JSONL)
- Returns processed content for downstream use (e.g., vector store ingestion)

## Request Format

```json
{
  "file_id": "file_abc123",
  "processor": "text_extraction",
  "params": {}
}
```

## Response Format

```json
{
  "file_id": "file_abc123",
  "processor": "text_extraction",
  "status": "completed",
  "output": {
    "chunks": [
      { "text": "...", "metadata": { "page": 1 } }
    ],
    "total_chunks": 15
  }
}
```

## Dependencies

- Files infrastructure (Phase 4)
- Text extraction libraries

## Status

- [ ] Controller
- [ ] Text processor
- [ ] CSV processor
- [ ] JSONL processor
