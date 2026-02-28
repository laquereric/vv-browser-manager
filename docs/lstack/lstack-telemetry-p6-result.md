# Telemetry — Phase 6 (Alpha)

API tier: **alpha (v1alpha)**
Controller: `llama_stack/alpha/telemetry_controller.rb`

## Endpoints

| Method | Path | Action |
|--------|------|--------|
| POST | `/v1alpha/telemetry/log-event` | Log a telemetry event |
| GET | `/v1alpha/telemetry/spans` | Query spans |
| GET | `/v1alpha/telemetry/traces` | Query traces |

## vv Backend

- Rails logger for event persistence
- RES events for structured telemetry
- Map to existing RES event timeline at `/res`

## Request Format (log-event)

```json
{
  "event": {
    "type": "structured_log",
    "message": "Inference completed",
    "severity": "info",
    "attributes": {
      "model": "llama3.2",
      "latency_ms": 1200,
      "tokens": 45
    },
    "timestamp": "2026-02-28T00:00:00Z"
  }
}
```

## Response Format (spans)

```json
{
  "object": "list",
  "data": [
    {
      "span_id": "span_abc",
      "trace_id": "trace_abc",
      "name": "inference.chat_completion",
      "start_time": "2026-02-28T00:00:00Z",
      "end_time": "2026-02-28T00:00:01Z",
      "attributes": { "model": "llama3.2" }
    }
  ]
}
```

## Dependencies

- Rails logger
- RES events (optional integration)

## Status

- [ ] Controller (log-event, spans, traces)
- [ ] Event persistence
