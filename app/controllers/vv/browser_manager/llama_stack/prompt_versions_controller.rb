module Vv
  module BrowserManager
    module LlamaStack
      class PromptVersionsController < BaseController
        # GET /v1/prompts/:prompt_id/versions
        def index
          prompt = Prompt.find(params[:prompt_id])
          data = prompt.versions.order(version: :desc).map { |v| format_version(v) }
          render json: ResponseFormatter.list(data)
        end

        # GET /v1/prompts/:prompt_id/versions/:version_id
        def show
          prompt = Prompt.find(params[:prompt_id])
          version = prompt.versions.find(params[:version_id])
          render json: format_version(version)
        end

        private

        def format_version(v)
          {
            id: v.id,
            prompt_id: v.prompt_id,
            version: v.version,
            template: v.template,
            variables: v.variables || [],
            created_at: v.created_at&.iso8601,
          }
        end
      end
    end
  end
end
