# Prompts — Phase 5 (Batch + Prompts)

API tier: **stable (v1)**
Controller: `llama_stack/prompts_controller.rb`

## Endpoints

| Method | Path | Action |
|--------|------|--------|
| GET | `/v1/prompts` | List prompts |
| GET | `/v1/prompts/:prompt_id` | Retrieve prompt |
| POST | `/v1/prompts` | Create prompt |
| POST | `/v1/prompts/:prompt_id` | Update prompt |
| DELETE | `/v1/prompts/:prompt_id` | Delete prompt |
| GET | `/v1/prompts/:prompt_id/versions` | List versions |
| GET | `/v1/prompts/:prompt_id/versions/:version_id` | Retrieve version |

## vv Backend

- New `vv_llama_prompts` + `vv_llama_prompt_versions` tables
- Version history for prompt templates
- Template variables with `{{variable}}` syntax

## New Tables

### `vv_llama_prompts`

| Column | Type | Notes |
|--------|------|-------|
| `id` | string (PK) | Prompt identifier |
| `name` | string | Display name |
| `description` | text | What this prompt does |
| `metadata` | json | |

### `vv_llama_prompt_versions`

| Column | Type | Notes |
|--------|------|-------|
| `id` | string (PK) | Version identifier |
| `prompt_id` | string (FK) | Parent prompt |
| `version` | integer | Auto-increment per prompt |
| `template` | text | Prompt template text |
| `variables` | json | Expected variable definitions |

## Response Format

```json
{
  "identifier": "form-validation",
  "name": "Form Validation",
  "description": "Validate form submission",
  "current_version": {
    "version": 3,
    "template": "Validate: {{form_data}}",
    "variables": ["form_data"]
  },
  "metadata": {}
}
```

## Status

- [x] Migrations (2 tables)
- [x] Models
- [x] Controller (CRUD + versions)
- [x] Verified: controllers load + migrations pass in test-host app (2026-02-28)
