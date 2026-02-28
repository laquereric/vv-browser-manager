# Dataset IO — Phase 6 (Beta)

API tier: **beta (v1beta)**
Controller: `llama_stack/beta/dataset_io_controller.rb`

## Endpoints

| Method | Path | Action |
|--------|------|--------|
| POST | `/v1beta/datasetio/append-rows/:dataset_id` | Append rows |
| GET | `/v1beta/datasetio/iterrows/:dataset_id` | Iterate rows |

## vv Backend

- New `vv_llama_dataset_rows` table
- Bulk append for data ingestion
- Paginated iteration for data retrieval

## New Table: `vv_llama_dataset_rows`

| Column | Type | Notes |
|--------|------|-------|
| `id` | bigint (PK) | Auto-increment |
| `dataset_id` | string (FK) | Parent dataset |
| `row_data` | json | Row content matching schema |
| `row_index` | integer | Position in dataset |

## Request Format (append-rows)

```json
{
  "rows": [
    { "input": "Validate: {name: ''}", "output": "{\"valid\": false}" },
    { "input": "Validate: {name: 'Alice'}", "output": "{\"valid\": true}" }
  ]
}
```

## Response Format (iterrows)

```json
{
  "object": "list",
  "data": [
    { "row_index": 0, "data": { "input": "...", "output": "..." } },
    { "row_index": 1, "data": { "input": "...", "output": "..." } }
  ],
  "has_more": true,
  "next_cursor": "100"
}
```

## Dependencies

- `vv_llama_datasets` table (from Datasets group)
- Migration for `vv_llama_dataset_rows`

## Status

- [ ] Migration
- [ ] Model
- [ ] Controller (append-rows, iterrows)
- [ ] Pagination
