module Vv
  module BrowserManager
    module LlamaStack
      class VectorStoreFile < ActiveRecord::Base
        self.table_name = "vv_llama_vector_store_files"
        belongs_to :vector_store, class_name: "Vv::BrowserManager::LlamaStack::VectorStore", optional: true
        belongs_to :llama_file, class_name: "Vv::BrowserManager::LlamaStack::LlamaFile", foreign_key: :file_id, optional: true
      end
    end
  end
end
