# Precharge: Model Lifecycle Management

## Overview

The Vv browser has access to multiple LLM providers — **MCL** (MediaPipe/Chrome Local) models running on-device via WebGPU, and **Ollama** models running on localhost. Models transition through three lifecycle states:

```
PRETRAINED ──→ PRECHARGED ──→ ACTIVE
 (cold)        (warm)         (responding)
```

| State | Description | Latency |
|-------|-------------|---------|
| **PRETRAINED** | Available but not loaded. Weights on disk (Ollama) or downloadable (MCL). | Seconds to minutes for first inference. |
| **PRECHARGED** | Loaded into memory with context already processed. Ready for follow-up inference with minimal latency. | Milliseconds — just the incremental generation. |
| **ACTIVE** | Currently processing a request. | N/A (busy). |

The precharge workflow prepares models before the user needs them, eliminating cold-start latency at the point of use — when a user is on a form and needs help *now*.

## Model Categories

### MCL (MediaPipe/Chrome Local)

- Runs in-browser via WebGPU
- No network calls — fully local inference
- Models downloaded on first use, cached by browser
- Examples: Gemma 2B, Gemma 7B

### Ollama

- Runs on localhost (typically port 11434)
- Server-managed model lifecycle (`ollama pull`, `ollama run`)
- Models persist on disk, loaded into GPU/CPU memory on demand
- Examples: llama3.1, mistral, phi-3

## Event Flow

Precharge follows the same RES + ActionCable pattern as `LlmRequested`/`LlmCompleted`:

```
Server (Ruby)                   RES                    Browser (JS)
─────────────                   ───                    ────────────
PrechargeClient.precharge(...)
  ↓
  [Publish] PrechargeRequested
  → stream "precharge:requests"
                                 ↓
                          LlmServer subscribes
                                 ↓
                          ActionCable broadcast
                          "#{prefix}:precharge:requests"
                                                        ↓
                                                  Receive request
                                                  Load model + process context
                                                  (MCL: load weights + KV cache
                                                   Ollama: /api/generate with keep_alive)
                                                        ↓
                                                  Send precharge:complete
                                                        ↓
                          EventBus handler calls
                          PrechargeClient.complete(...)
                                 ↓
                          [Publish] PrechargeCompleted
                          → stream "precharge:responses"
                                 ↓
PrechargeClient polls / callback
returns PrechargeResult
```

## RES Events

### PrechargeRequested

Published by `PrechargeClient` when the server wants a model warmed up.

```ruby
Vv::BrowserManager::Events::PrechargeRequested.new(
  data: {
    correlation_id: "uuid",
    model_id: "gemma-2b",           # model identifier (from ModelRegistry)
    category: "mcl",                 # "mcl" or "ollama"
    context: [                       # messages to pre-process
      { role: "system", content: "You are a form assistant..." },
      { role: "user", content: "{\"name\":\"\",\"ssn\":\"\",\"dob\":\"\"}" }
    ],
    priority: "normal",              # "high" | "normal" | "low"
  },
  metadata: { correlation_id: "uuid" }
)
```

### PrechargeCompleted

Published by browser (via EventBus → `PrechargeClient.complete`) when the model is warm.

```ruby
Vv::BrowserManager::Events::PrechargeCompleted.new(
  data: {
    correlation_id: "uuid",
    model_id: "gemma-2b",
    category: "mcl",
    status: "ready",                 # "ready" | "failed" | "already_warm"
    context_tokens: 245,             # tokens processed during precharge
    load_time_ms: 1200,              # time to load model weights
    prefill_time_ms: 80,             # time to process context
    error: nil,                      # error message if status == "failed"
  },
  metadata: { correlation_id: "uuid" }
)
```

## PrechargeClient API

```ruby
# Precharge a model with context (non-blocking, returns immediately)
Vv::BrowserManager::PrechargeClient.precharge(
  model_id: "gemma-2b",
  category: "mcl",
  context: messages,                 # array of {role:, content:} hashes
  priority: "normal"
)
# => correlation_id (String)

# Precharge and block until ready (for sequential workflows)
result = Vv::BrowserManager::PrechargeClient.precharge_and_wait(
  model_id: "gemma-2b",
  category: "mcl",
  context: messages,
  timeout: 30
)
# => PrechargeResult { status:, model_id:, context_tokens:, load_time_ms:, prefill_time_ms: }

# Check if a model is already precharged
Vv::BrowserManager::PrechargeClient.warm?(model_id: "gemma-2b")
# => true/false (checks ModelRegistry state)
```

## When to Precharge

Precharge is triggered by **anticipation** — the server knows something is likely to happen before the user asks.

| Trigger | What to Precharge | Why |
|---------|-------------------|-----|
| `FormOpened` event | Load model + form schema as system context | User will likely need help soon |
| `FieldHelpRequested` on field A | Precharge with context for neighboring fields | User exploring the form |
| `FormErrorOccurred` | Precharge with error context | Error resolution turn is imminent |
| Session created | Precharge default model with system prompt | Baseline readiness |
| `FormPolled` with long pause on a field | Precharge with that field's context | User is stuck |

## Integration with LlmClient.infer

When `LlmClient.infer` is called and the target model is already precharged, the browser skips weight loading and context processing — it goes straight to incremental generation. The browser manages this transparently; the server doesn't need to know whether the model was warm.

The precharge is a **hint**, not a requirement. If the browser receives an `llm:request` for a model that wasn't precharged, it loads normally (PRETRAINED → ACTIVE, skipping PRECHARGED). Precharge just removes the latency.

## Model Selection for Precharge

The server uses `ModelRegistry` (see model discovery) to know which models are available in the browser. Precharge targets are selected by:

1. **Capability match** — model supports the task (e.g., form assistance, code generation)
2. **Category preference** — MCL preferred for privacy-sensitive fields (SSN, DOB), Ollama for larger context
3. **Resource awareness** — don't precharge more models than the browser can hold in memory

## Lifecycle State Tracking

`ModelRegistry` tracks each model's current state:

```ruby
Vv::BrowserManager::ModelRegistry.status("gemma-2b")
# => :pretrained | :precharged | :active | :unavailable

Vv::BrowserManager::ModelRegistry.precharged_models
# => [{ model_id: "gemma-2b", category: "mcl", context_tokens: 245, since: Time }]
```

State transitions are driven by events:

```
ModelsDiscovered    → :pretrained (or :unavailable if removed)
PrechargeCompleted  → :precharged (if status == "ready")
LlmRequested        → :active (while processing)
LlmCompleted        → :precharged (returns to warm state with updated context)
```

## Future Considerations

- **Eviction** — when browser memory is constrained, which precharged model to unload first (LRU by last inference time)
- **Context refresh** — as new form events arrive, re-precharge with updated context (debounced)
- **Multi-model precharge** — precharge both an MCL model (fast, private) and an Ollama model (capable, larger context) so the server can choose at inference time based on the request
- **Precharge warming schedules** — configurable per-app policies for which models to keep warm
