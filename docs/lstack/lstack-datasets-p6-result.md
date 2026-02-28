# Datasets — Phase 6 (Beta)

API tier: **beta (v1beta)**
Controller: `llama_stack/beta/datasets_controller.rb`

## Endpoints

| Method | Path | Action |
|--------|------|--------|
| GET | `/v1beta/datasets` | List datasets |
| POST | `/v1beta/datasets` | Register dataset |
| GET | `/v1beta/datasets/:dataset_id` | Retrieve dataset |
| DELETE | `/v1beta/datasets/:dataset_id` | Unregister dataset |

## vv Backend

- New `vv_llama_datasets` table
- Dataset = metadata container for rows (actual data in DatasetIO)

## New Table: `vv_llama_datasets`

| Column | Type | Notes |
|--------|------|-------|
| `id` | string (PK) | Dataset identifier |
| `name` | string | Display name |
| `description` | text | Dataset description |
| `schema` | json | Column definitions |
| `metadata` | json | |
| `row_count` | integer | Cached count |

## Response Format

```json
{
  "identifier": "training-data-v1",
  "name": "Training Data v1",
  "description": "Form validation training examples",
  "schema": {
    "columns": [
      { "name": "input", "type": "string" },
      { "name": "output", "type": "string" }
    ]
  },
  "metadata": {},
  "row_count": 1500
}
```

## Dependencies

- Migration

## Status

- [ ] Migration
- [ ] Model
- [ ] Controller (CRUD)
