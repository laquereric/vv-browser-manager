module Vv
  module BrowserManager
    module LlamaStack
      class Tool < ActiveRecord::Base
        self.table_name = "vv_llama_tools"
        belongs_to :tool_group, class_name: "Vv::BrowserManager::LlamaStack::ToolGroup", optional: true
      end
    end
  end
end
