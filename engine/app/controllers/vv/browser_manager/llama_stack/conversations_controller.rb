module Vv
  module BrowserManager
    module LlamaStack
      class ConversationsController < BaseController
        # POST /v1/conversations
        def create
          return unprocessable("Session table not available") unless session_model

          session = session_model.create!(
            title: params.dig(:metadata, :title) || "Untitled",
            metadata: params[:metadata] || {},
          )
          render json: ResponseFormatter.conversation(session), status: :created
        end

        # GET /v1/conversations/:conversation_id
        def show
          session = find_session!
          render json: ResponseFormatter.conversation(session)
        end

        # POST /v1/conversations/:conversation_id/update
        def update
          session = find_session!
          session.update!(
            title: params.dig(:metadata, :title) || session.title,
            metadata: params[:metadata] || session.metadata,
          )
          render json: ResponseFormatter.conversation(session)
        end

        # DELETE /v1/conversations/:conversation_id
        def destroy
          session = find_session!
          session.destroy!
          render json: { status: "ok" }
        end

        # GET /v1/conversations/:conversation_id/items
        def items
          session = find_session!
          events = session.events

          # Pagination
          limit = (params[:limit] || 100).to_i
          offset = 0
          if params[:after].present?
            idx = events.index { |e| e.event_id == params[:after] }
            offset = idx ? idx + 1 : 0
          end

          page = events[offset, limit] || []
          has_more = (offset + limit) < events.size

          data = page.map { |event| format_event_as_item(event) }
          render json: ResponseFormatter.list(data, has_more: has_more)
        end

        # GET /v1/conversations/:conversation_id/items/:item_id
        def show_item
          session = find_session!
          event = session.events.find { |e| e.event_id == params[:item_id] }
          return not_found("Item not found: #{params[:item_id]}") unless event

          render json: format_event_as_item(event)
        end

        private

        def find_session!
          raise ActiveRecord::RecordNotFound, "Session table not available" unless session_model
          session_model.find(params[:conversation_id])
        end

        def format_event_as_item(event)
          msg = Vv::Rails::Events.to_message_hash(event) if defined?(Vv::Rails::Events)
          {
            item_id: event.event_id,
            type: "message",
            role: msg&.dig(:role) || event.event_type.demodulize.underscore,
            content: [{ type: "text", text: msg&.dig(:content) || event.data.to_json }],
            created_at: event.metadata[:timestamp]&.iso8601 || event.metadata[:valid_at]&.iso8601,
          }
        end
      end
    end
  end
end
