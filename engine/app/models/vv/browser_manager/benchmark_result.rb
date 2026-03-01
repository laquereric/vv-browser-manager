module Vv
  module BrowserManager
    class BenchmarkResult < ActiveRecord::Base
      self.table_name = "vv_benchmark_results"

      belongs_to :benchmark_query

      validates :model_id, presence: true
      validates :score, numericality: { in: 0.0..1.0 }, allow_nil: true

      scope :by_model, ->(model_id) { where(model_id: model_id) }
      scope :by_category, ->(category) { where(model_category: category) }
      scope :latest_per_model, -> {
        where(
          id: select("MAX(id)")
                .group(:model_id, :benchmark_query_id)
        )
      }

      def passed?
        format_valid? && keys_present?
      end

      def score_breakdown
        {
          format_valid: format_valid?,
          keys_present: keys_present?,
          score: score,
          latency_ms: latency_ms,
        }
      end
    end
  end
end
