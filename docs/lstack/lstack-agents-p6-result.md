# Agents — Phase 6 (Alpha)

API tier: **alpha (v1alpha)**
Controller: `llama_stack/alpha/agents_controller.rb`

## Endpoints

| Method | Path | Action |
|--------|------|--------|
| POST | `/v1alpha/agents` | Create agent |
| GET | `/v1alpha/agents/:agent_id` | Retrieve agent |
| DELETE | `/v1alpha/agents/:agent_id` | Delete agent |
| POST | `/v1alpha/agents/:agent_id/sessions` | Create session |
| GET | `/v1alpha/agents/:agent_id/sessions/:session_id` | Get session |
| DELETE | `/v1alpha/agents/:agent_id/sessions/:session_id` | Delete session |
| POST | `/v1alpha/agents/:agent_id/sessions/:session_id/turns` | Create turn (streaming) |
| GET | `/v1alpha/agents/:agent_id/sessions/:session_id/turns/:turn_id` | Get turn |

## vv Backend

- New `vv_llama_agents` table for agent configs
- Session maps to host app `Session` with agent metadata
- Turn maps to host app `Turn` with streaming via SSE
- Agent config defines: model, tools, instructions, sampling_params

## New Table: `vv_llama_agents`

| Column | Type | Notes |
|--------|------|-------|
| `id` | string (PK) | Agent identifier |
| `model` | string | Default model |
| `instructions` | text | System prompt |
| `sampling_params` | json | temperature, top_p, etc. |
| `tools` | json | Tool group references |
| `input_shields` | json | Safety shield IDs |
| `output_shields` | json | Safety shield IDs |
| `max_infer_iters` | integer | Max tool-use iterations |

## Response Format (agent)

```json
{
  "agent_id": "agent_abc123",
  "agent_config": {
    "model": "meta-llama/Llama-3.2-3B-Instruct",
    "instructions": "You are a helpful assistant.",
    "sampling_params": { "temperature": 0.7 },
    "tools": [{ "type": "brave_search" }],
    "max_infer_iters": 5
  }
}
```

## Response Format (turn — streaming SSE)

```
data: {"event":{"payload":{"event_type":"turn_start","turn_id":"turn_abc"}}}

data: {"event":{"payload":{"event_type":"step_progress","delta":"Hello"}}}

data: {"event":{"payload":{"event_type":"turn_complete","turn":{"turn_id":"turn_abc","output_message":{"content":"Hello!"}}}}}
```

## Dependencies

- Migration for `vv_llama_agents`
- Host app `Session`, `Turn` tables
- ProviderClient for inference
- Tool runtime (Phase 4) for tool-use loops
- Safety infrastructure (Phase 3) for shields

## Status

- [ ] Migration
- [ ] Model
- [ ] Controller (agent CRUD)
- [ ] Controller (session CRUD)
- [ ] Controller (turn create with streaming)
- [ ] Tool-use loop
- [ ] Safety shield integration
