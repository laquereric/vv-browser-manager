module Vv
  module BrowserManager
    module LlamaStack
      class PromptsController < BaseController
        # GET /v1/prompts
        def index
          prompts = Prompt.all
          data = prompts.map { |p| format_prompt(p) }
          render json: ResponseFormatter.list(data)
        end

        # GET /v1/prompts/:prompt_id
        def show
          prompt = Prompt.find(params[:prompt_id])
          render json: format_prompt(prompt)
        end

        # POST /v1/prompts
        def create
          prompt = Prompt.create!(
            id: params[:identifier] || params[:prompt_id] || "prompt_#{SecureRandom.hex(8)}",
            name: params[:name],
            description: params[:description],
            metadata: params[:metadata] || {},
          )

          # Create initial version if template provided
          if params[:template].present?
            prompt.versions.create!(
              version: 1,
              template: params[:template],
              variables: params[:variables] || [],
            )
          end

          render json: format_prompt(prompt), status: :created
        end

        # POST /v1/prompts/:prompt_id/update
        def update
          prompt = Prompt.find(params[:prompt_id])
          prompt.update!(
            name: params[:name] || prompt.name,
            description: params[:description] || prompt.description,
            metadata: params[:metadata] || prompt.metadata,
          )

          # Create new version if template changed
          if params[:template].present?
            next_version = (prompt.versions.maximum(:version) || 0) + 1
            prompt.versions.create!(
              version: next_version,
              template: params[:template],
              variables: params[:variables] || [],
            )
          end

          render json: format_prompt(prompt.reload)
        end

        # DELETE /v1/prompts/:prompt_id
        def destroy
          prompt = Prompt.find(params[:prompt_id])
          prompt.destroy!
          render json: { status: "ok" }
        end

        private

        def format_prompt(p)
          cv = p.current_version
          result = {
            identifier: p.id,
            name: p.name,
            description: p.description,
            metadata: p.metadata || {},
          }
          if cv
            result[:current_version] = {
              version: cv.version,
              template: cv.template,
              variables: cv.variables || [],
            }
          end
          result
        end
      end
    end
  end
end
