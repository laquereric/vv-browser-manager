namespace :vv do
  namespace :benchmark do
    desc "Seed/update benchmark queries"
    task seed: :environment do
      Vv::BrowserManager::BenchmarkQuery.seed!
      count = Vv::BrowserManager::BenchmarkQuery.count
      puts "Seeded #{count} benchmark queries"
    end

    desc "List all benchmark queries"
    task list: :environment do
      queries = Vv::BrowserManager::BenchmarkQuery.order(:category, :name)
      if queries.empty?
        puts "No benchmark queries. Run: rails vv:benchmark:seed"
        next
      end

      puts format("%-35s %-20s %-8s %s", "Name", "Category", "Format", "Expected Keys")
      puts "-" * 90
      queries.each do |q|
        keys = (q.expected_keys || []).join(", ")
        puts format("%-35s %-20s %-8s %s", q.name, q.category, q.expected_format, keys)
      end
      puts "\n#{queries.count} queries total"
    end

    desc "Run benchmarks (QUERY=name MODEL=id CATEGORY=ollama)"
    task run: :environment do
      model_id = ENV["MODEL"]
      query_name = ENV["QUERY"]
      model_category = ENV["CATEGORY"] || "ollama"
      api_base = ENV["API_BASE"] || "http://localhost:11434"

      # Resolve model: use ENV, or detect from Ollama/registry
      unless model_id
        # Try browser registry first
        available = Vv::BrowserManager.model_registry.available
        if available.any?
          model_id = available.first.model_id
          model_category = available.first.category
          puts "Auto-selected browser model: #{model_id} (#{model_category})"
        elsif model_category == "ollama"
          # Try detecting from Ollama API
          begin
            require "net/http"
            resp = Net::HTTP.get(URI("#{api_base}/api/tags"))
            models = JSON.parse(resp)["models"]
            if models&.any?
              model_id = models.first["name"]
              puts "Auto-selected Ollama model: #{model_id}"
              puts "  Available: #{models.map { |m| m['name'] }.join(', ')}"
            end
          rescue => e
            # Ollama not reachable
          end
        end

        unless model_id
          puts "No MODEL specified and no models available."
          puts "Usage: rails vv:benchmark:run MODEL=llama3.1"
          puts "       rails vv:benchmark:run MODEL=gemma3 CATEGORY=ollama"
          next
        end
      end

      config = { api_base: api_base }
      config[:temperature] = ENV["TEMPERATURE"].to_f if ENV["TEMPERATURE"]
      config[:max_tokens] = ENV["MAX_TOKENS"].to_i if ENV["MAX_TOKENS"]
      config[:timeout] = ENV["TIMEOUT"].to_i if ENV["TIMEOUT"]

      queries = if query_name
        Vv::BrowserManager::BenchmarkQuery.where(name: query_name)
      else
        Vv::BrowserManager::BenchmarkQuery.all
      end

      if queries.empty?
        puts "No queries found. Run: rails vv:benchmark:seed"
        next
      end

      puts "Running #{queries.count} benchmarks against #{model_id} (#{model_category})...\n\n"

      queries.each do |query|
        print "  #{query.name}... "
        $stdout.flush

        begin
          result = Vv::BrowserManager::Benchmark.run(
            query, model_id: model_id, model_category: model_category, config: config
          )
          status = result.passed? ? "PASS" : "FAIL"
          tokens = [result.input_tokens, result.output_tokens].compact.any? ?
            "  tokens=#{result.input_tokens || '?'}/#{result.output_tokens || '?'}" : ""
          puts format("%-6s score=%.2f  latency=%dms%s", status, result.score || 0, result.latency_ms || 0, tokens)
          puts "    #{result.notes}" unless result.passed?
        rescue => e
          puts "ERROR: #{e.message}"
        end
      end

      puts "\nDone."
    end

    desc "Show results summary (MODEL=id)"
    task results: :environment do
      model_id = ENV["MODEL"]

      scope = Vv::BrowserManager::BenchmarkResult.includes(:benchmark_query).order(created_at: :desc)
      scope = scope.by_model(model_id) if model_id

      if scope.empty?
        puts "No benchmark results yet. Run: rails vv:benchmark:run MODEL=<model>"
        next
      end

      # Group by model, show latest result per query
      grouped = scope.group_by(&:model_id)
      grouped.each do |mid, results|
        puts "\n== #{mid} =="
        puts format("  %-35s %-6s %-7s %-10s %s", "Query", "Status", "Score", "Latency", "Notes")
        puts "  " + "-" * 85

        # Latest per query
        seen = {}
        results.each do |r|
          qname = r.benchmark_query.name
          next if seen[qname]
          seen[qname] = true

          status = r.passed? ? "PASS" : "FAIL"
          notes = r.notes.to_s.truncate(40)
          puts format("  %-35s %-6s %-7.3f %-10s %s", qname, status, r.score || 0, "#{r.latency_ms}ms", notes)
        end

        scores = results.map(&:score).compact
        avg = scores.any? ? (scores.sum / scores.length).round(3) : 0
        pass_count = results.count(&:passed?)
        puts format("\n  Avg score: %.3f  Pass rate: %d/%d (%.0f%%)", avg, pass_count, seen.size, seen.size > 0 ? (pass_count.to_f / seen.size * 100) : 0)
      end
    end

    desc "Run benchmarks via ActionCable pipeline (SERVER=url QUERY=name MODEL=id TIMEOUT=60)"
    task pipeline: :environment do
      require "net/http"
      require "json"

      server = ENV["SERVER"] || "http://localhost:3003"
      query_name = ENV["QUERY"]
      model_id = ENV["MODEL"]
      timeout = ENV["TIMEOUT"] || "60"

      # Build request
      uri = URI("#{server}/vv/benchmark/run")
      body = { timeout: timeout.to_i }
      body[:query_name] = query_name if query_name
      body[:model_id] = model_id if model_id

      puts "Running benchmarks via pipeline at #{server}..."
      puts "  Model: #{model_id || '(auto-detect from browser)'}"
      puts "  Query: #{query_name || '(all)'}"
      puts ""

      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = 600  # long timeout for full suite
      http.open_timeout = 5
      req = Net::HTTP::Post.new(uri.path, "Content-Type" => "application/json")
      req.body = body.to_json

      begin
        resp = http.request(req)
      rescue Errno::ECONNREFUSED
        puts "Cannot connect to #{server}. Is the server running?"
        puts "  Start it with: cd /tmp/test-example && bin/rails server -p 3003"
        next
      end

      if resp.code != "200"
        data = JSON.parse(resp.body) rescue {}
        puts "Server error (#{resp.code}): #{data['error'] || resp.body}"
        next
      end

      data = JSON.parse(resp.body)
      puts "Model: #{data['model_id']} (#{data['model_category']})\n\n"

      data["results"].each do |r|
        status = r["passed"] ? "PASS" : "FAIL"
        tokens = [r["input_tokens"], r["output_tokens"]].compact.any? ?
          "  tokens=#{r['input_tokens'] || '?'}/#{r['output_tokens'] || '?'}" : ""
        puts format("  %-35s %-6s score=%.2f  latency=%dms%s",
          r["query"], status, r["score"] || 0, r["latency_ms"] || 0, tokens)
        puts "    #{r['notes']}" unless r["passed"]
      end

      s = data["summary"]
      puts format("\nSummary: %d/%d passed  avg_score=%.3f  avg_latency=%dms",
        s["passed"], s["total"], s["avg_score"], s["avg_latency_ms"])
    end

    desc "Side-by-side model comparison"
    task compare: :environment do
      comparison = Vv::BrowserManager::Benchmark.compare
      if comparison.empty?
        puts "No benchmark results to compare. Run benchmarks first."
        next
      end

      puts format("%-25s %-12s %-12s %-10s %s", "Model", "Avg Score", "Avg Latency", "Pass Rate", "Runs")
      puts "-" * 70

      comparison.sort_by { |_, v| -(v[:avg_score] || 0) }.each do |model_id, stats|
        puts format(
          "%-25s %-12.3f %-12s %-10s %d",
          model_id.truncate(25),
          stats[:avg_score] || 0,
          "#{stats[:avg_latency_ms]}ms",
          "#{(stats[:pass_rate] * 100).round(0)}%",
          stats[:count]
        )
      end
    end
  end
end
