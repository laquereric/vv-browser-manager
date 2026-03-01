module Vv
  module BrowserManager
    module LlamaStack
      class ScoringController < BaseController
        # POST /v1/scoring/score
        def score
          input_rows = params[:input_rows]
          scoring_functions = params[:scoring_functions]

          return bad_request("input_rows is required") unless input_rows.present?
          return bad_request("scoring_functions is required") unless scoring_functions.present?

          results = {}
          scoring_functions.each_key do |fn_name|
            fn_name = fn_name.to_s
            score_rows = input_rows.map do |row|
              row = row.respond_to?(:to_unsafe_h) ? row.to_unsafe_h : row
              compute_score(fn_name, row)
            end

            scores = score_rows.map { |r| r[:score] }
            avg = scores.any? ? (scores.sum / scores.size).round(3) : 0.0

            results[fn_name] = {
              score_rows: score_rows,
              aggregated_results: { average: avg },
            }
          end

          render json: { results: results }
        end

        # POST /v1/scoring/score-batch
        def score_batch
          # Same as score but accepts dataset_id for batch processing
          score
        end

        private

        def compute_score(fn_name, row)
          output = row["output"].to_s
          expected = row["expected_output"].to_s

          case fn_name
          when "exact_match"
            s = output.strip == expected.strip ? 1.0 : 0.0
            { score: s, metadata: {} }
          when "contains"
            s = output.include?(expected) ? 1.0 : 0.0
            { score: s, metadata: {} }
          when "format_valid"
            begin
              JSON.parse(output)
              { score: 1.0, metadata: { format: "json" } }
            rescue
              s = output.strip.empty? ? 0.0 : 0.5
              { score: s, metadata: { format: "text" } }
            end
          when "length"
            s = output.length > 0 ? [output.length / [expected.length, 1].max.to_f, 1.0].min.round(3) : 0.0
            { score: s, metadata: { output_length: output.length } }
          else
            # Default: basic similarity
            s = output == expected ? 1.0 : (output.include?(expected) ? 0.5 : 0.0)
            { score: s, metadata: {} }
          end
        end
      end
    end
  end
end
