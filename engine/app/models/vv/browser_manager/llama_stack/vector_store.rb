module Vv
  module BrowserManager
    module LlamaStack
      class VectorStore < ActiveRecord::Base
        self.table_name = "vv_llama_vector_stores"
        has_many :vector_store_files, class_name: "Vv::BrowserManager::LlamaStack::VectorStoreFile", foreign_key: :vector_store_id
      end
    end
  end
end
