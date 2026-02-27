module Vv
  module BrowserManager
    class BenchmarkController < ActionController::API
      # POST /vv/benchmark/run
      # Params: query_name (optional), model_id (optional), timeout (optional)
      #
      # Runs inside the server process so LlmClient can access the
      # in-memory RES event store and ActionCable broadcasts.
      def run
        query_name = params[:query_name]
        model_id = params[:model_id]
        timeout = (params[:timeout] || 60).to_i

        queries = if query_name.present?
          BenchmarkQuery.where(name: query_name)
        else
          BenchmarkQuery.all
        end

        if queries.empty?
          render json: { error: "No queries found. Run: rails vv:benchmark:seed" }, status: :not_found
          return
        end

        # Auto-select model from registry if not provided
        unless model_id.present?
          available = Vv::BrowserManager.model_registry.available
          if available.any?
            model_id = available.first.model_id
          else
            render json: { error: "No model_id provided and no browser models available" }, status: :unprocessable_entity
            return
          end
        end

        model_category = Vv::BrowserManager.model_registry.find(model_id)&.category || "unknown"

        results = queries.map do |query|
          result = Benchmark.run(query, model_id: model_id, model_category: model_category, config: { timeout: timeout })
          {
            query: query.name,
            category: query.category,
            passed: result.passed?,
            score: result.score,
            latency_ms: result.latency_ms,
            input_tokens: result.input_tokens,
            output_tokens: result.output_tokens,
            format_valid: result.format_valid,
            keys_present: result.keys_present,
            notes: result.notes,
          }
        end

        render json: {
          model_id: model_id,
          model_category: model_category,
          results: results,
          summary: {
            total: results.size,
            passed: results.count { |r| r[:passed] },
            avg_score: results.map { |r| r[:score] }.compact.then { |s| s.any? ? (s.sum / s.size).round(3) : 0 },
            avg_latency_ms: results.map { |r| r[:latency_ms] }.compact.then { |s| s.any? ? (s.sum / s.size).round(0).to_i : 0 },
          }
        }
      end
    end
  end
end
