# Llama Stack API routes — drawn into the host app's router
# Controllers are namespaced under Vv::BrowserManager::LlamaStack

scope module: "vv/browser_manager/llama_stack" do
  # === Phase 1: Core Inference ===

  # Inspect / Health
  get "v1/health",          to: "inspect#health"
  get "v1/version",         to: "inspect#version"
  get "v1/inspect/routes",  to: "routes#index"

  # Models
  get    "v1/models",       to: "models#index"
  get    "v1/models/:id",   to: "models#show"
  post   "v1/models",       to: "models#create"
  delete "v1/models/:id",   to: "models#destroy"

  # Providers
  get "v1/providers",       to: "providers#index"
  get "v1/providers/:id",   to: "providers#show"

  # Inference (Llama Stack native)
  post "v1/inference/chat-completion", to: "inference#chat_completion"
  post "v1/inference/completion",      to: "inference#completion"
  post "v1/inference/embeddings",      to: "inference#embeddings"

  # Chat (OpenAI-compatible)
  post "v1/chat/completions",      to: "chat#create"
  get  "v1/chat/completions/:id",  to: "chat#show"

  # Completions (OpenAI-compatible)
  post "v1/completions", to: "completions#create"

  # Embeddings (OpenAI-compatible)
  post "v1/embeddings", to: "embeddings#create"

  # === Phase 2: Conversations + Responses ===

  # Conversations
  post   "v1/conversations",                                    to: "conversations#create"
  get    "v1/conversations/:conversation_id",                   to: "conversations#show"
  post   "v1/conversations/:conversation_id/update",            to: "conversations#update"
  delete "v1/conversations/:conversation_id",                   to: "conversations#destroy"
  get    "v1/conversations/:conversation_id/items",             to: "conversations#items"
  get    "v1/conversations/:conversation_id/items/:item_id",    to: "conversations#show_item"

  # Responses
  post   "v1/responses",                            to: "responses#create"
  get    "v1/responses/:response_id",               to: "responses#show"
  delete "v1/responses/:response_id",               to: "responses#destroy"
  get    "v1/responses/:response_id/input_items",   to: "responses#input_items"

  # === Phase 3: Safety + Scoring ===

  # Shields
  get    "v1/shields",              to: "shields#index"
  get    "v1/shields/:identifier",  to: "shields#show"
  post   "v1/shields",              to: "shields#create"
  delete "v1/shields/:identifier",  to: "shields#destroy"

  # Safety
  post "v1/safety/run-shield", to: "safety#run_shield"

  # Scoring
  post "v1/scoring/score",       to: "scoring#score"
  post "v1/scoring/score-batch", to: "scoring#score_batch"

  # Scoring Functions
  get    "v1/scoring-functions",       to: "scoring_functions#index"
  get    "v1/scoring-functions/:id",   to: "scoring_functions#show"
  post   "v1/scoring-functions",       to: "scoring_functions#create"
  delete "v1/scoring-functions/:id",   to: "scoring_functions#destroy"

  # === Phase 4: Tools + RAG ===

  # Tool Groups
  get    "v1/toolgroups",       to: "tool_groups#index"
  get    "v1/toolgroups/:id",   to: "tool_groups#show"
  post   "v1/toolgroups",       to: "tool_groups#create"
  delete "v1/toolgroups/:id",   to: "tool_groups#destroy"

  # Tools
  get "v1/tools",       to: "tools#index"
  get "v1/tools/:id",   to: "tools#show"

  # Tool Runtime
  post "v1/tool-runtime/invoke",     to: "tool_runtime#invoke"
  get  "v1/tool-runtime/list-tools", to: "tool_runtime#list_tools"

  # Vector Stores
  get    "v1/vector_stores",                                                   to: "vector_stores#index"
  post   "v1/vector_stores",                                                   to: "vector_stores#create"
  get    "v1/vector_stores/:vector_store_id",                                  to: "vector_stores#show"
  post   "v1/vector_stores/:vector_store_id/update",                           to: "vector_stores#update"
  delete "v1/vector_stores/:vector_store_id",                                  to: "vector_stores#destroy"
  post   "v1/vector_stores/:vector_store_id/search",                           to: "vector_stores#search"
  get    "v1/vector_stores/:vector_store_id/files",                            to: "vector_store_files#index"
  post   "v1/vector_stores/:vector_store_id/files",                            to: "vector_store_files#create"
  get    "v1/vector_stores/:vector_store_id/files/:file_id",                   to: "vector_store_files#show"
  post   "v1/vector_stores/:vector_store_id/files/:file_id/update",            to: "vector_store_files#update"
  delete "v1/vector_stores/:vector_store_id/files/:file_id",                   to: "vector_store_files#destroy"
  get    "v1/vector_stores/:vector_store_id/files/:file_id/content",           to: "vector_store_files#content"
  post   "v1/vector_stores/:vector_store_id/file_batches",                     to: "vector_store_file_batches#create"
  get    "v1/vector_stores/:vector_store_id/file_batches/:batch_id",           to: "vector_store_file_batches#show"
  post   "v1/vector_stores/:vector_store_id/file_batches/:batch_id/cancel",    to: "vector_store_file_batches#cancel"
  get    "v1/vector_stores/:vector_store_id/file_batches/:batch_id/files",     to: "vector_store_file_batches#files"

  # Files
  get    "v1/files",                  to: "files#index"
  post   "v1/files",                  to: "files#create"
  get    "v1/files/:file_id",         to: "files#show"
  delete "v1/files/:file_id",         to: "files#destroy"
  get    "v1/files/:file_id/content", to: "files#content"

  # === Phase 5: Batches + Prompts + Moderations ===

  # Batches
  get  "v1/batches",                    to: "batches#index"
  post "v1/batches",                    to: "batches#create"
  get  "v1/batches/:batch_id",          to: "batches#show"
  post "v1/batches/:batch_id/cancel",   to: "batches#cancel"

  # Prompts
  get    "v1/prompts",                                      to: "prompts#index"
  get    "v1/prompts/:prompt_id",                           to: "prompts#show"
  post   "v1/prompts",                                      to: "prompts#create"
  post   "v1/prompts/:prompt_id/update",                    to: "prompts#update"
  delete "v1/prompts/:prompt_id",                           to: "prompts#destroy"
  get    "v1/prompts/:prompt_id/versions",                  to: "prompt_versions#index"
  get    "v1/prompts/:prompt_id/versions/:version_id",      to: "prompt_versions#show"

  # Moderations
  post "v1/moderations", to: "moderations#create"

  # === Phase 6: Alpha ===

  scope "v1alpha", module: "alpha" do
    # Agents
    post   "agents",                                                to: "agents#create"
    get    "agents/:agent_id",                                      to: "agents#show"
    delete "agents/:agent_id",                                      to: "agents#destroy"
    post   "agents/:agent_id/sessions",                             to: "agents#create_session"
    get    "agents/:agent_id/sessions/:session_id",                 to: "agents#show_session"
    delete "agents/:agent_id/sessions/:session_id",                 to: "agents#destroy_session"
    post   "agents/:agent_id/sessions/:session_id/turns",           to: "agents#create_turn"
    get    "agents/:agent_id/sessions/:session_id/turns/:turn_id",  to: "agents#show_turn"

    # Post-Training
    get  "post-training/jobs",                        to: "post_training#index"
    post "post-training/supervised-fine-tune",        to: "post_training#supervised_fine_tune"
    post "post-training/preference-optimize",         to: "post_training#preference_optimize"
    get  "post-training/jobs/:job_uuid/status",       to: "post_training#status"
    post "post-training/jobs/:job_uuid/cancel",       to: "post_training#cancel"
    get  "post-training/jobs/:job_uuid/artifacts",    to: "post_training#artifacts"

    # Eval / Benchmarks
    get    "eval/benchmarks",                                       to: "benchmarks#index"
    post   "eval/benchmarks",                                       to: "benchmarks#create"
    get    "eval/benchmarks/:benchmark_id",                         to: "benchmarks#show"
    delete "eval/benchmarks/:benchmark_id",                         to: "benchmarks#destroy"
    post   "eval/benchmarks/:benchmark_id/evaluations",             to: "benchmarks#evaluate"
    post   "eval/benchmarks/:benchmark_id/jobs",                    to: "benchmarks#create_job"
    get    "eval/benchmarks/:benchmark_id/jobs/:job_id",            to: "benchmarks#show_job"
    delete "eval/benchmarks/:benchmark_id/jobs/:job_id",            to: "benchmarks#destroy_job"
    get    "eval/benchmarks/:benchmark_id/jobs/:job_id/result",     to: "benchmarks#job_result"

    # Admin
    get "admin/health",                         to: "admin#health"
    get "admin/version",                        to: "admin#version"
    get "admin/providers",                      to: "admin#providers"
    get "admin/providers/:provider_id",         to: "admin#show_provider"
    get "admin/inspect/routes",                 to: "admin#routes"

    # Connectors
    get "connectors",                                      to: "connectors#index"
    get "connectors/:connector_id",                        to: "connectors#show"
    get "connectors/:connector_id/tools",                  to: "connectors#tools"
    get "connectors/:connector_id/tools/:tool_name",       to: "connectors#show_tool"

    # File Processors
    post "file-processors/process", to: "file_processors#process"

    # Telemetry
    post "telemetry/log-event", to: "telemetry#log_event"
    get  "telemetry/spans",     to: "telemetry#spans"
    get  "telemetry/traces",    to: "telemetry#traces"
  end

  # === Phase 6: Beta ===

  scope "v1beta", module: "beta" do
    # Datasets
    get    "datasets",              to: "datasets#index"
    post   "datasets",              to: "datasets#create"
    get    "datasets/:dataset_id",  to: "datasets#show"
    delete "datasets/:dataset_id",  to: "datasets#destroy"

    # Dataset IO
    post "datasetio/append-rows/:dataset_id", to: "dataset_io#append_rows"
    get  "datasetio/iterrows/:dataset_id",    to: "dataset_io#iterrows"
  end
end
