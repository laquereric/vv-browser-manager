require "json"
require "net/http"
require "uri"

module Vv
  module BrowserManager
    module Benchmark
      # Run a single benchmark query against a model.
      # Uses direct Ollama HTTP when model_category is "ollama" (or api_base provided),
      # otherwise falls back to LlmClient (ActionCable → browser).
      # Returns the saved BenchmarkResult.
      def self.run(query, model_id:, model_category: nil, config: {})
        model_category ||= resolve_category(model_id)

        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        response, token_info = infer(query, model_id: model_id, model_category: model_category, config: config)
        elapsed_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).round

        format_valid, keys_present, score, notes = score_response(query, response)

        BenchmarkResult.create!(
          benchmark_query: query,
          model_id: model_id,
          model_category: model_category,
          response: response,
          latency_ms: elapsed_ms,
          input_tokens: token_info&.dig(:input_tokens),
          output_tokens: token_info&.dig(:output_tokens),
          format_valid: format_valid,
          keys_present: keys_present,
          score: score,
          notes: notes,
          config: config,
        )
      end

      # Run all queries (or filtered) against a model.
      def self.run_all(model_id:, model_category: nil, query_name: nil, config: {})
        queries = if query_name
          BenchmarkQuery.where(name: query_name)
        else
          BenchmarkQuery.all
        end

        queries.map do |query|
          run(query, model_id: model_id, model_category: model_category, config: config)
        end
      end

      # Compare models: returns a hash of { model_id => { avg_score, avg_latency, count, pass_rate } }
      def self.compare(model_ids: nil)
        scope = BenchmarkResult.all
        scope = scope.where(model_id: model_ids) if model_ids

        scope.group(:model_id).pluck(
          :model_id,
          Arel.sql("AVG(score)"),
          Arel.sql("AVG(latency_ms)"),
          Arel.sql("COUNT(*)"),
          Arel.sql("SUM(CASE WHEN format_valid AND keys_present THEN 1 ELSE 0 END)"),
        ).to_h do |model_id, avg_score, avg_latency, count, pass_count|
          [model_id, {
            avg_score: avg_score&.round(3),
            avg_latency_ms: avg_latency&.round(0)&.to_i,
            count: count,
            pass_rate: count > 0 ? (pass_count.to_f / count).round(3) : 0.0,
          }]
        end
      end

      # Infer via direct HTTP (Ollama) or ActionCable (browser).
      # Returns [response_text, token_info_hash_or_nil].
      def self.infer(query, model_id:, model_category:, config: {})
        api_base = config[:api_base] || "http://localhost:11434"

        if model_category == "ollama" || config[:direct]
          ollama_infer(query, model_id: model_id, api_base: api_base, config: config)
        else
          response = LlmClient.infer(
            query.user_prompt,
            system_prompt: query.system_prompt,
            timeout: config[:timeout] || 120
          )
          [response, nil]
        end
      end

      # Direct Ollama HTTP chat completion.
      def self.ollama_infer(query, model_id:, api_base:, config: {})
        uri = URI("#{api_base}/api/chat")

        messages = []
        messages << { role: "system", content: query.system_prompt } if query.system_prompt.present?
        messages << { role: "user", content: query.user_prompt }

        body = {
          model: model_id,
          messages: messages,
          stream: false,
          options: {
            temperature: config[:temperature] || 0.3,
            num_predict: config[:max_tokens] || 1024,
          },
        }

        http = Net::HTTP.new(uri.host, uri.port)
        http.read_timeout = config[:timeout] || 120
        http.open_timeout = 10

        request = Net::HTTP::Post.new(uri.path, "Content-Type" => "application/json")
        request.body = body.to_json

        resp = http.request(request)
        data = JSON.parse(resp.body)

        content = data.dig("message", "content")
        token_info = {
          input_tokens: data["prompt_eval_count"],
          output_tokens: data["eval_count"],
        }

        [content, token_info]
      rescue => e
        [nil, nil]
      end

      private

      def self.score_response(query, response)
        return [false, false, 0.0, "No response (timeout or no browser connected)"] if response.nil?

        score = 0.0
        notes = []

        # Check format
        format_valid = false
        parsed = nil
        if query.expected_format == "json"
          begin
            cleaned = strip_markdown_fences(response)
            parsed = JSON.parse(cleaned)
            format_valid = parsed.is_a?(Hash)
            score += 0.3 if format_valid
          rescue JSON::ParserError => e
            notes << "JSON parse error: #{e.message}"
          end
        else
          format_valid = response.is_a?(String) && !response.strip.empty?
          score += 0.3 if format_valid
        end

        # Check expected keys
        expected = query.expected_keys || []
        keys_present = false
        if format_valid && parsed.is_a?(Hash) && expected.any?
          present = expected.all? { |k| parsed.key?(k) }
          keys_present = present
          score += 0.3 if present
          notes << "Missing keys: #{(expected - parsed.keys).join(', ')}" unless present
        elsif expected.empty?
          keys_present = true
          score += 0.3
        end

        # Response quality (rule-based, 0.4 max)
        quality = 0.0
        if response && !response.strip.empty?
          # Not empty
          quality += 0.1

          # Reasonable length
          quality += 0.1 if response.length > 10 && response.length < 2000

          if parsed.is_a?(Hash)
            # For validation queries: answer is decisive
            if parsed["answer"]
              quality += 0.1 if %w[yes no].include?(parsed["answer"].to_s.downcase)
            else
              quality += 0.1
            end

            # Values are non-trivial
            non_empty_values = parsed.values.count { |v| v.is_a?(String) ? !v.strip.empty? : !v.nil? }
            quality += 0.1 if non_empty_values >= expected.length
          elsif format_valid
            quality += 0.2
          end
        end
        score += quality

        score = score.clamp(0.0, 1.0).round(3)
        notes << "Score: #{score}" if notes.empty?

        [format_valid, keys_present, score, notes.join("; ")]
      end

      # Strip ```json ... ``` fences that LLMs commonly wrap responses in.
      def self.strip_markdown_fences(text)
        stripped = text.strip
        if stripped.start_with?("```")
          # Remove opening fence (```json, ```JSON, ```, etc.)
          stripped = stripped.sub(/\A```\w*\s*\n?/, "")
          # Remove closing fence
          stripped = stripped.sub(/\n?```\s*\z/, "")
        end
        stripped.strip
      end

      def self.resolve_category(model_id)
        entry = Vv::BrowserManager.model_registry.find(model_id)
        entry&.category || "unknown"
      end
    end
  end
end
