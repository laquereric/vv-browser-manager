# Eval / Benchmarks — Phase 6 (Alpha)

API tier: **alpha (v1alpha)**
Controller: `llama_stack/alpha/eval_controller.rb`, `llama_stack/alpha/benchmarks_controller.rb`

## Endpoints

| Method | Path | Action |
|--------|------|--------|
| GET | `/v1alpha/eval/benchmarks` | List benchmarks |
| POST | `/v1alpha/eval/benchmarks` | Register benchmark |
| GET | `/v1alpha/eval/benchmarks/:benchmark_id` | Retrieve benchmark |
| DELETE | `/v1alpha/eval/benchmarks/:benchmark_id` | Unregister benchmark |
| POST | `/v1alpha/eval/benchmarks/:benchmark_id/evaluations` | Evaluate rows |
| POST | `/v1alpha/eval/benchmarks/:benchmark_id/jobs` | Run eval job |
| GET | `/v1alpha/eval/benchmarks/:benchmark_id/jobs/:job_id` | Job status |
| DELETE | `/v1alpha/eval/benchmarks/:benchmark_id/jobs/:job_id` | Cancel job |
| GET | `/v1alpha/eval/benchmarks/:benchmark_id/jobs/:job_id/result` | Job result |

## vv Backend

- Reuses existing `BenchmarkQuery` + `BenchmarkResult` tables
- `BenchmarkQuery` categories map to benchmark definitions
- `Benchmark.run_all` powers eval jobs
- `Benchmark.compare` powers job results

## Mapping: vv → Llama Stack

| vv Model | Llama Stack |
|----------|-------------|
| `BenchmarkQuery` | Benchmark definition |
| `BenchmarkQuery.category` | Benchmark category grouping |
| `BenchmarkResult` | Evaluation result row |
| `Benchmark.run_all` | Job execution |
| `Benchmark.compare` | Aggregated results |

## Response Format (benchmark)

```json
{
  "identifier": "form_validation",
  "description": "Test form validation inference quality",
  "scoring_functions": ["format_valid", "keys_present", "quality"],
  "metadata": { "query_count": 5 }
}
```

## Dependencies

- Existing `BenchmarkQuery`, `BenchmarkResult` models
- Existing `Benchmark` module
- ActiveJob for async eval jobs

## Status

- [ ] Controller (benchmark CRUD)
- [ ] Controller (evaluations)
- [ ] Controller (jobs CRUD + status)
- [ ] Map BenchmarkQuery → Benchmark definition
- [ ] Map BenchmarkResult → Eval result
