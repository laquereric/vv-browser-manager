module Vv
  module BrowserManager
    module LlamaStack
      class Prompt < ActiveRecord::Base
        self.table_name = "vv_llama_prompts"
        has_many :versions, class_name: "Vv::BrowserManager::LlamaStack::PromptVersion", foreign_key: :prompt_id, dependent: :destroy

        def current_version
          versions.order(version: :desc).first
        end
      end
    end
  end
end
