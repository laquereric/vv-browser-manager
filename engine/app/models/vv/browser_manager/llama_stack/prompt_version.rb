module Vv
  module BrowserManager
    module LlamaStack
      class PromptVersion < ActiveRecord::Base
        self.table_name = "vv_llama_prompt_versions"
        belongs_to :prompt, class_name: "Vv::BrowserManager::LlamaStack::Prompt"
      end
    end
  end
end
