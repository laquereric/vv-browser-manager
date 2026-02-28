# Connectors — Phase 6 (Alpha)

API tier: **alpha (v1alpha)**
Controller: `llama_stack/alpha/connectors_controller.rb`

## Endpoints

| Method | Path | Action |
|--------|------|--------|
| GET | `/v1alpha/connectors` | List connectors |
| GET | `/v1alpha/connectors/:connector_id` | Retrieve connector |
| GET | `/v1alpha/connectors/:connector_id/tools` | List connector tools |
| GET | `/v1alpha/connectors/:connector_id/tools/:tool_name` | Retrieve tool |

## vv Backend

- New `vv_llama_connectors` table
- Connector = external service integration (MCP server, API, etc.)
- Each connector exposes tools

## New Table: `vv_llama_connectors`

| Column | Type | Notes |
|--------|------|-------|
| `id` | string (PK) | Connector identifier |
| `name` | string | Display name |
| `connector_type` | string | "mcp", "api", "plugin" |
| `endpoint` | json | Connection config |
| `metadata` | json | |

## Response Format

```json
{
  "connector_id": "brave-search",
  "name": "Brave Search",
  "connector_type": "mcp",
  "endpoint": { "uri": "http://localhost:8080/mcp" },
  "tools": [
    { "tool_name": "search", "description": "Web search" }
  ]
}
```

## Dependencies

- Migration
- Tool infrastructure (Phase 4)

## Status

- [ ] Migration
- [ ] Model
- [ ] Controller (CRUD + tools)
