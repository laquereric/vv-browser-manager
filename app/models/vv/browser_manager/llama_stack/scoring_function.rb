module Vv
  module BrowserManager
    module LlamaStack
      class ScoringFunction < ActiveRecord::Base
        self.table_name = "vv_llama_scoring_functions"
      end
    end
  end
end
