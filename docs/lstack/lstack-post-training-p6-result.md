# Post-Training — Phase 6 (Alpha)

API tier: **alpha (v1alpha)**
Controller: `llama_stack/alpha/post_training_controller.rb`

## Endpoints

| Method | Path | Action |
|--------|------|--------|
| GET | `/v1alpha/post-training/jobs` | List jobs |
| POST | `/v1alpha/post-training/supervised-fine-tune` | Start SFT job |
| POST | `/v1alpha/post-training/preference-optimize` | Start DPO/RLHF job |
| GET | `/v1alpha/post-training/jobs/:job_uuid/status` | Job status |
| POST | `/v1alpha/post-training/jobs/:job_uuid/cancel` | Cancel job |
| GET | `/v1alpha/post-training/jobs/:job_uuid/artifacts` | Get artifacts |

## vv Backend

- New `vv_llama_training_jobs` table
- Background jobs (ActiveJob) for training dispatch
- Delegates to Ollama model creation or external training service

## Response Format (job)

```json
{
  "job_uuid": "job_abc123",
  "status": "running",
  "model": "meta-llama/Llama-3.2-3B-Instruct",
  "algorithm": "sft",
  "dataset_id": "dataset_abc",
  "created_at": "2026-02-28T00:00:00Z"
}
```

## Dependencies

- ActiveJob for background processing
- Datasets infrastructure (Beta)

## Status

- [ ] Migration
- [ ] Model
- [ ] Controller (CRUD + status)
- [ ] Background job
