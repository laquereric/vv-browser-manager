module Vv
  module BrowserManager
    module LlamaStack
      class ToolGroupsController < BaseController
        # GET /v1/toolgroups
        def index
          groups = ToolGroup.all
          data = groups.map { |g| format_group(g) }
          render json: ResponseFormatter.list(data)
        end

        # GET /v1/toolgroups/:id
        def show
          group = ToolGroup.find(params[:id])
          render json: format_group(group)
        end

        # POST /v1/toolgroups
        def create
          group = ToolGroup.create!(
            id: params[:toolgroup_id] || params[:identifier],
            provider_id: params[:provider_id],
            provider_resource_id: params[:provider_resource_id],
            toolgroup_type: params[:toolgroup_type] || "generic",
            mcp_endpoint: params[:mcp_endpoint],
            args: params[:args] || {},
          )
          render json: format_group(group), status: :created
        end

        # DELETE /v1/toolgroups/:id
        def destroy
          group = ToolGroup.find(params[:id])
          group.destroy!
          render json: { status: "ok" }
        end

        private

        def format_group(g)
          result = {
            identifier: g.id,
            provider_id: g.provider_id,
            provider_resource_id: g.provider_resource_id,
            toolgroup_type: g.toolgroup_type,
            args: g.args || {},
          }
          result[:mcp_endpoint] = g.mcp_endpoint if g.mcp_endpoint.present?
          result
        end
      end
    end
  end
end
