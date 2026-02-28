# Tools — Phase 4 (Tools + RAG)

API tier: **stable (v1)**
Controller: `llama_stack/tools_controller.rb`

## Endpoints

| Method | Path | Action |
|--------|------|--------|
| GET | `/v1/tools` | List tools |
| GET | `/v1/tools/:tool_name` | Retrieve tool |

## vv Backend

- New `vv_llama_tools` table
- Tools belong to a tool group
- Describes function signature for LLM tool-use

## New Table: `vv_llama_tools`

| Column | Type | Notes |
|--------|------|-------|
| `id` | string (PK) | Tool name |
| `tool_group_id` | string (FK) | Parent group |
| `description` | text | Tool description |
| `parameters` | json | JSON Schema for inputs |
| `metadata` | json | Additional tool config |

## Response Format

```json
{
  "identifier": "web-search::search",
  "toolgroup_id": "web-search",
  "description": "Search the web",
  "parameters": {
    "type": "object",
    "properties": { "query": { "type": "string" } },
    "required": ["query"]
  },
  "metadata": {}
}
```

## Status

- [x] Migration
- [x] Model
- [x] Controller (list, retrieve)
- [x] Verified: controllers load + migrations pass in test-host app (2026-02-28)
