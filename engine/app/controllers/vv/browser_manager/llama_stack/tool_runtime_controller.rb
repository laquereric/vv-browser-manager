module Vv
  module BrowserManager
    module LlamaStack
      class ToolRuntimeController < BaseController
        # POST /v1/tool-runtime/invoke
        def invoke
          tool_name = params[:tool_name]
          args = params[:args] || {}

          return bad_request("tool_name is required") unless tool_name.present?

          tool = Tool.find_by(id: tool_name)
          return not_found("Tool not found: #{tool_name}") unless tool

          # TODO: Implement actual tool dispatch (MCP, built-in handlers)
          render json: {
            content: "Tool '#{tool_name}' invocation not yet implemented",
            error_code: nil,
            error_message: nil,
          }
        end

        # GET /v1/tool-runtime/list-tools
        def list_tools
          tools = Tool.all
          tools = tools.where(tool_group_id: params[:toolgroup_id]) if params[:toolgroup_id].present?
          data = tools.map { |t| { identifier: t.id, description: t.description, parameters: t.parameters || {} } }
          render json: ResponseFormatter.list(data)
        end
      end
    end
  end
end
