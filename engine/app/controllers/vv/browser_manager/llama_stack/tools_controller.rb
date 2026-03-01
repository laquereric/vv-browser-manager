module Vv
  module BrowserManager
    module LlamaStack
      class ToolsController < BaseController
        # GET /v1/tools
        def index
          tools = Tool.all
          tools = tools.where(tool_group_id: params[:toolgroup_id]) if params[:toolgroup_id].present?
          data = tools.map { |t| format_tool(t) }
          render json: ResponseFormatter.list(data)
        end

        # GET /v1/tools/:id
        def show
          tool = Tool.find(params[:id])
          render json: format_tool(tool)
        end

        private

        def format_tool(t)
          {
            identifier: t.id,
            toolgroup_id: t.tool_group_id,
            description: t.description,
            parameters: t.parameters || {},
            metadata: t.metadata || {},
          }
        end
      end
    end
  end
end
