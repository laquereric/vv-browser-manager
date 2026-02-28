module Vv
  module BrowserManager
    module LlamaStack
      class ToolGroup < ActiveRecord::Base
        self.table_name = "vv_llama_tool_groups"
        has_many :tools, class_name: "Vv::BrowserManager::LlamaStack::Tool", foreign_key: :tool_group_id
      end
    end
  end
end
