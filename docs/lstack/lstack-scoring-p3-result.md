# Scoring — Phase 3

API tier: **stable (v1)**
Controller: `llama_stack/scoring_controller.rb`

## Endpoints

| Method | Path | Action |
|--------|------|--------|
| POST | `/v1/scoring/score` | Score a single response |
| POST | `/v1/scoring/score-batch` | Score a batch of responses |

## vv Backend

- Reuses `Benchmark.score_response` logic
- Applies registered scoring functions

## Request Format

```json
{
  "input_rows": [{ "input": "What is 2+2?", "output": "4", "expected_output": "4" }],
  "scoring_functions": { "accuracy": {} }
}
```

## Response Format

```json
{
  "results": {
    "accuracy": {
      "score_rows": [{ "score": 1.0, "metadata": {} }],
      "aggregated_results": { "average": 1.0 }
    }
  }
}
```

## Dependencies

- `vv_llama_scoring_functions` table
- Existing `Benchmark.score_response`

## Status

- [x] Controller (score, score-batch)
- [x] Scoring function dispatch (exact_match, contains, format_valid, length)
- [x] Verified: controllers load + migrations pass in test-host app (2026-02-28)
