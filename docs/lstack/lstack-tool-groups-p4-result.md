# Tool Groups — Phase 4 (Tools + RAG)

API tier: **stable (v1)**
Controller: `llama_stack/tool_groups_controller.rb`

## Endpoints

| Method | Path | Action |
|--------|------|--------|
| GET | `/v1/toolgroups` | List tool groups |
| GET | `/v1/toolgroups/:toolgroup_id` | Retrieve tool group |
| POST | `/v1/toolgroups` | Register tool group |
| DELETE | `/v1/toolgroups/:toolgroup_id` | Unregister tool group |

## vv Backend

- New `vv_llama_tool_groups` table
- Groups related tools for agent configurations

## New Table: `vv_llama_tool_groups`

| Column | Type | Notes |
|--------|------|-------|
| `id` | string (PK) | Group identifier |
| `provider_id` | string | Provider hosting tools |
| `mcp_endpoint` | json | Optional MCP server config |
| `args` | json | Group-level arguments |

## Response Format

```json
{
  "identifier": "web-search",
  "provider_id": "builtin",
  "provider_resource_id": "web-search",
  "toolgroup_type": "mcp",
  "mcp_endpoint": { "uri": "http://localhost:8080" },
  "args": {}
}
```

## Status

- [x] Migration
- [x] Model
- [x] Controller (CRUD)
- [x] Verified: controllers load + migrations pass in test-host app (2026-02-28)
