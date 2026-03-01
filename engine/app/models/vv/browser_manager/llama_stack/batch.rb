module Vv
  module BrowserManager
    module LlamaStack
      class Batch < ActiveRecord::Base
        self.table_name = "vv_llama_batches"
      end
    end
  end
end
