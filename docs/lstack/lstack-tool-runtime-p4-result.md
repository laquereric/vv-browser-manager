# Tool Runtime — Phase 4 (Tools + RAG)

API tier: **stable (v1)**
Controller: `llama_stack/tool_runtime_controller.rb`

## Endpoints

| Method | Path | Action |
|--------|------|--------|
| POST | `/v1/tool-runtime/invoke` | Invoke a tool |
| GET | `/v1/tool-runtime/list-tools` | List available tools at runtime |

## vv Backend

- Looks up tool definition from `vv_llama_tools`
- Dispatches to tool implementation (MCP, built-in, or plugin)
- Returns structured tool output

## Request Format (invoke)

```json
{
  "tool_name": "web-search::search",
  "args": { "query": "latest news" },
  "kwargs": {}
}
```

## Response Format

```json
{
  "content": "Search results...",
  "error_code": null,
  "error_message": null
}
```

## Dependencies

- `vv_llama_tools`, `vv_llama_tool_groups` tables
- Tool dispatch logic (MCP client, built-in handlers)

## Status

- [x] Controller (invoke, list-tools)
- [ ] Tool dispatch logic (stub -- TODO)
- [x] Verified: controllers load + migrations pass in test-host app (2026-02-28)
