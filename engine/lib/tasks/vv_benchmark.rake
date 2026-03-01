require "fileutils"

namespace :vv do
  namespace :benchmark do
    # ── Shared config ──────────────────────────────────────────────────
    DOCS_DIR = ENV.fetch("BENCH_DIR", File.expand_path("~/Documents/Focus/vv-platform/docs"))
    SKIP_MODELS = %w[
      nomic-embed-text mxbai-embed-large
      llava minicpm-v llama3.2-vision
      deepseek-v3
    ].freeze

    # ── Helpers ────────────────────────────────────────────────────────

    def self.today = Time.now.strftime("%Y%m%d")
    def self.timestamp = Time.now.strftime("%Y-%m-%d %H:%M")

    def self.ollama_models(api_base = "http://localhost:11434")
      require "net/http"
      resp = Net::HTTP.get(URI("#{api_base}/api/tags"))
      JSON.parse(resp)["models"]
          .map { |m| m["name"].sub(/:latest$/, "") }
          .reject { |n| SKIP_MODELS.any? { |s| n.start_with?(s) } }
          .sort
    rescue => e
      warn "Ollama unreachable: #{e.message}"
      []
    end

    def self.resolve_model(env_model, api_base)
      return env_model if env_model

      available = Vv::BrowserManager.model_registry.available
      if available.any?
        return available.first.model_id
      end

      models = ollama_models(api_base)
      models.first
    end

    # Fetch latest non-timeout result per model/query
    def self.latest_results
      all = Vv::BrowserManager::BenchmarkResult
              .includes(:benchmark_query)
              .order(:created_at)

      best = {}
      all.each do |r|
        key = "#{r.model_id}:#{r.benchmark_query_id}"
        is_timeout = r.notes&.include?("timeout") || r.notes&.include?("No response")
        # Prefer non-timeout; among equals take latest
        if !best[key] || (!is_timeout) || (best[key].notes&.include?("timeout"))
          best[key] = r unless is_timeout && best[key] && !best[key].notes&.include?("timeout")
        end
      end
      # Simpler: group, prefer non-timeout, then latest
      grouped = all.group_by { |r| "#{r.model_id}:#{r.benchmark_query_id}" }
      grouped.transform_values do |rs|
        good = rs.reject { |r| r.notes&.include?("timeout") || r.notes&.include?("No response") }
        (good.any? ? good : rs).last
      end
    end

    # ── Markdown writers ───────────────────────────────────────────────

    def self.write_results_md(path, model_results: nil)
      queries = Vv::BrowserManager::BenchmarkQuery.order(:category, :name)
      latest = latest_results

      models = if model_results
        model_results.keys.sort
      else
        latest.values.map(&:model_id).uniq.sort
      end
      categories = queries.map(&:category).uniq

      md = []
      md << "# Vv Benchmark Results"
      md << ""
      md << "Generated: #{timestamp}"
      md << ""
      md << "#{queries.count} queries across #{categories.size} categories: #{categories.join(', ')}"
      md << ""

      # Summary
      md << "## Summary"
      md << ""
      md << "| Model | Queries | Pass | Fail | Avg Latency | Avg Score |"
      md << "|-------|---------|------|------|-------------|-----------|"
      models.each do |m|
        mr = latest.values.select { |r| r.model_id == m }
        next if mr.empty?
        pass = mr.count(&:passed?)
        avg_lat = (mr.sum(&:latency_ms).to_f / mr.size / 1000).round(1)
        avg_score = (mr.sum { |r| r.score || 0 }.to_f / mr.size).round(3)
        md << "| #{m} | #{mr.size} | #{pass} | #{mr.size - pass} | #{avg_lat}s | #{avg_score} |"
      end

      # Comparison matrix for models with full runs
      full_count = queries.count
      full_models = models.select { |m| latest.values.count { |r| r.model_id == m } >= full_count }

      if full_models.size > 1
        md << ""
        md << "## Comparison Matrix"
        md << ""
        header = "| Query | Category |"
        sep    = "|-------|----------|"
        full_models.each { |m| header += " #{m} |"; sep += "------|" }
        md << header
        md << sep

        queries.each do |q|
          row = "| #{q.name} | #{q.category} |"
          full_models.each do |m|
            r = latest["#{m}:#{q.id}"]
            if r
              s = r.passed? ? "PASS" : "FAIL"
              row += " #{s} #{(r.latency_ms / 1000.0).round(1)}s |"
            else
              row += " — |"
            end
          end
          md << row
        end
      end

      # Per-model detail
      models.each do |m|
        mr = latest.values
                .select { |r| r.model_id == m }
                .sort_by { |r| [r.benchmark_query&.category.to_s, r.benchmark_query&.name.to_s] }
        next if mr.empty?

        md << ""
        md << "## #{m}"
        md << ""
        pass = mr.count(&:passed?)
        avg_lat = (mr.sum(&:latency_ms).to_f / mr.size / 1000).round(1)
        avg_score = (mr.sum { |r| r.score || 0 }.to_f / mr.size).round(3)
        md << "- **Queries:** #{mr.size}"
        md << "- **Pass:** #{pass}/#{mr.size}"
        md << "- **Avg Latency:** #{avg_lat}s"
        md << "- **Avg Score:** #{avg_score}"
        md << ""
        md << "| Query | Category | Status | Latency | Score |"
        md << "|-------|----------|--------|---------|-------|"
        mr.each do |r|
          q = r.benchmark_query
          s = r.passed? ? "PASS" : "FAIL"
          md << "| #{q&.name} | #{q&.category} | #{s} | #{(r.latency_ms / 1000.0).round(1)}s | #{r.score} |"
        end

        failures = mr.reject(&:passed?)
        if failures.any?
          md << ""
          md << "### Failures"
          md << ""
          failures.each do |r|
            q = r.benchmark_query
            md << "**#{q&.name}** (#{q&.category})"
            md << ""
            md << "- format_valid: #{r.format_valid}"
            md << "- keys_present: #{r.keys_present}"
            md << "- notes: #{r.notes}"
            md << "- response: `#{(r.response || '')[0..200].gsub("\n", ' ')}`"
            md << ""
          end
        end
      end

      # Category breakdown
      if full_models.size > 1
        md << ""
        md << "## Category Breakdown"
        md << ""
        categories.each do |cat|
          cat_qs = queries.where(category: cat)
          md << "### #{cat} (#{cat_qs.size} queries)"
          md << ""
          md << "| Model | Pass | Avg Latency | Avg Score |"
          md << "|-------|------|-------------|-----------|"
          full_models.each do |m|
            cr = cat_qs.map { |q| latest["#{m}:#{q.id}"] }.compact
            next if cr.empty?
            pass = cr.count(&:passed?)
            avg_lat = (cr.sum(&:latency_ms).to_f / cr.size / 1000).round(1)
            avg_score = (cr.sum { |r| r.score || 0 }.to_f / cr.size).round(3)
            md << "| #{m} | #{pass}/#{cr.size} | #{avg_lat}s | #{avg_score} |"
          end
          md << ""
        end
      end

      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, md.join("\n") + "\n")
      puts "  Wrote #{path} (#{md.size} lines)"
    end

    def self.write_leaderboard_md(path)
      latest = latest_results
      queries = Vv::BrowserManager::BenchmarkQuery.order(:category, :name)
      full_count = queries.count

      # Build per-model stats from latest non-timeout results
      by_model = latest.values.group_by(&:model_id)

      rows = by_model.map do |model_id, results|
        pass = results.count(&:passed?)
        total = results.size
        avg_score = (results.sum { |r| r.score || 0 }.to_f / total).round(3)
        avg_lat = (results.sum(&:latency_ms).to_f / total / 1000).round(1)
        min_lat = (results.map(&:latency_ms).min / 1000.0).round(1)
        max_lat = (results.map(&:latency_ms).max / 1000.0).round(1)
        {
          model: model_id, pass: pass, total: total,
          score: avg_score, avg_lat: avg_lat, min_lat: min_lat, max_lat: max_lat,
          complete: total >= full_count
        }
      end.sort_by { |r| [-r[:score], r[:avg_lat]] }

      md = []
      md << "# Vv Benchmark Leaderboard"
      md << ""
      md << "Generated: #{timestamp}"
      md << ""
      md << "#{full_count} benchmark queries | #{by_model.size} models tested"
      md << ""

      # Podium
      complete = rows.select { |r| r[:complete] }
      if complete.size >= 1
        md << "## Podium (complete runs only)"
        md << ""
        medals = ["1.", "2.", "3."]
        complete.first(3).each_with_index do |r, i|
          md << "#{medals[i]} **#{r[:model]}** — #{r[:pass]}/#{r[:total]} pass, #{r[:score]} score, #{r[:avg_lat]}s avg"
        end
        md << ""
      end

      md << "## Full Leaderboard"
      md << ""
      md << "| Rank | Model | Pass | Score | Avg Latency | Min | Max | Complete |"
      md << "|------|-------|------|-------|-------------|-----|-----|----------|"
      rows.each_with_index do |r, i|
        flag = r[:complete] ? "yes" : "#{r[:total]}/#{full_count}"
        md << "| #{i + 1} | #{r[:model]} | #{r[:pass]}/#{r[:total]} | #{r[:score]} | #{r[:avg_lat]}s | #{r[:min_lat]}s | #{r[:max_lat]}s | #{flag} |"
      end

      # Category leaders (among complete models only)
      if complete.size >= 2
        categories = queries.map(&:category).uniq
        md << ""
        md << "## Category Leaders"
        md << ""
        md << "| Category | Best Model | Score | Avg Latency |"
        md << "|----------|------------|-------|-------------|"
        categories.each do |cat|
          cat_qs = queries.where(category: cat)
          best_model = nil
          best_score = -1
          best_lat = 0
          complete.each do |row|
            cr = cat_qs.map { |q| latest["#{row[:model]}:#{q.id}"] }.compact
            next if cr.empty?
            cs = (cr.sum { |r| r.score || 0 }.to_f / cr.size).round(3)
            cl = (cr.sum(&:latency_ms).to_f / cr.size / 1000).round(1)
            if cs > best_score || (cs == best_score && cl < best_lat)
              best_model = row[:model]
              best_score = cs
              best_lat = cl
            end
          end
          md << "| #{cat} | #{best_model} | #{best_score} | #{best_lat}s |" if best_model
        end
      end

      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, md.join("\n") + "\n")
      puts "  Wrote #{path} (#{md.size} lines)"
    end

    # ── Tasks ──────────────────────────────────────────────────────────

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

      model_id = resolve_model(model_id, api_base)
      unless model_id
        puts "No MODEL specified and no models available."
        puts "Usage: rails vv:benchmark:run MODEL=llama3.1"
        next
      end
      # Strip :latest suffix
      model_id = model_id.sub(/:latest$/, "")

      config = { api_base: api_base }
      config[:temperature] = ENV["TEMPERATURE"].to_f if ENV["TEMPERATURE"]
      config[:max_tokens] = ENV["MAX_TOKENS"].to_i if ENV["MAX_TOKENS"]
      config[:timeout] = ENV["TIMEOUT"].to_i if ENV["TIMEOUT"]

      queries = query_name ? Vv::BrowserManager::BenchmarkQuery.where(name: query_name) : Vv::BrowserManager::BenchmarkQuery.all
      if queries.empty?
        puts "No queries found. Run: rails vv:benchmark:seed"
        next
      end

      puts "Running #{queries.count} benchmarks against #{model_id} (#{model_category})...\n\n"

      queries.order(:category, :name).each_with_index do |query, i|
        print "  [#{i + 1}/#{queries.count}] #{query.name.ljust(40)} "
        $stdout.flush

        begin
          result = Vv::BrowserManager::Benchmark.run(
            query, model_id: model_id, model_category: model_category, config: config
          )
          status = result.passed? ? "PASS" : "FAIL"
          lat = (result.latency_ms / 1000.0).round(1)
          puts format("%-6s %.2f  %ss", status, result.score || 0, lat)
          puts "         #{result.notes}" unless result.passed?
        rescue => e
          puts "ERROR: #{e.message}"
        end
      end

      puts "\nDone. Writing results..."
      path = File.join(DOCS_DIR, "benchmark-results_#{today}.md")
      write_results_md(path)
    end

    desc "Continuous loop: benchmark all Ollama models, write results after each (SKIP=model1,model2)"
    task sweep: :environment do
      api_base = ENV["API_BASE"] || "http://localhost:11434"
      skip_extra = (ENV["SKIP"] || "").split(",").map(&:strip)

      config = { api_base: api_base }
      config[:temperature] = ENV["TEMPERATURE"].to_f if ENV["TEMPERATURE"]
      config[:max_tokens] = ENV["MAX_TOKENS"].to_i if ENV["MAX_TOKENS"]
      config[:timeout] = (ENV["TIMEOUT"] || "120").to_i

      queries = Vv::BrowserManager::BenchmarkQuery.order(:category, :name)
      if queries.empty?
        puts "No queries. Run: rails vv:benchmark:seed"
        next
      end

      models = ollama_models(api_base) - skip_extra
      if models.empty?
        puts "No Ollama models available."
        next
      end

      # Skip models that already have a full run today
      already_done = Vv::BrowserManager::BenchmarkResult
        .where("created_at >= ?", Time.current.beginning_of_day)
        .where.not("notes LIKE ?", "%timeout%")
        .where.not("notes LIKE ?", "%No response%")
        .group(:model_id)
        .having("COUNT(DISTINCT benchmark_query_id) >= ?", queries.count)
        .pluck(:model_id)

      remaining = models - already_done
      puts "Ollama models:   #{models.size} available, #{already_done.size} already done today"
      puts "Remaining:       #{remaining.join(', ')}"
      puts "Queries:         #{queries.count}"
      puts "Total runs:      #{remaining.size * queries.count}"
      puts "=" * 70

      remaining.each_with_index do |model, mi|
        puts "\n#{"=" * 70}"
        puts "[#{mi + 1}/#{remaining.size}] MODEL: #{model}"
        puts "=" * 70

        pass = 0
        fail_count = 0

        queries.each_with_index do |query, qi|
          print "  [#{qi + 1}/#{queries.count}] #{query.name.ljust(40)} "
          $stdout.flush

          begin
            result = Vv::BrowserManager::Benchmark.run(
              query, model_id: model, model_category: "ollama", config: config
            )
            status = result.passed? ? "PASS" : "FAIL"
            lat = (result.latency_ms / 1000.0).round(1)
            puts format("%-6s %.2f  %ss", status, result.score || 0, lat)
            puts "         #{result.notes}" unless result.passed?
            result.passed? ? pass += 1 : fail_count += 1
          rescue => e
            puts "ERROR  #{e.message[0..60]}"
            fail_count += 1
          end
        end

        puts "  >> #{model}: #{pass}/#{queries.count} pass, #{fail_count} fail"

        # Write results after each model
        path = File.join(DOCS_DIR, "benchmark-results_#{today}.md")
        write_results_md(path)
      end

      puts "\n#{"=" * 70}"
      puts "SWEEP COMPLETE — #{remaining.size} models benchmarked"

      # Final leaderboard
      lb_path = File.join(DOCS_DIR, "leaderboard_#{today}.md")
      write_leaderboard_md(lb_path)
    end

    desc "Write leaderboard from existing results"
    task leaderboard: :environment do
      path = File.join(DOCS_DIR, "leaderboard_#{today}.md")
      write_leaderboard_md(path)

      # Also write full results
      results_path = File.join(DOCS_DIR, "benchmark-results_#{today}.md")
      write_results_md(results_path)
    end

    desc "Focus: benchmark a small model set, write focus.md (MODELS=a,b,c CATEGORY=form_validation)"
    task focus: :environment do
      api_base = ENV["API_BASE"] || "http://localhost:11434"
      model_list = ENV["MODELS"]&.split(",")&.map(&:strip)
      category = ENV["CATEGORY"]

      unless model_list&.any?
        puts "Usage: rails vv:benchmark:focus MODELS=gemma3,phi4,llama3.2"
        puts "       rails vv:benchmark:focus MODELS=gemma3,phi4 CATEGORY=form_validation"
        next
      end

      config = { api_base: api_base }
      config[:temperature] = ENV["TEMPERATURE"].to_f if ENV["TEMPERATURE"]
      config[:max_tokens] = ENV["MAX_TOKENS"].to_i if ENV["MAX_TOKENS"]
      config[:timeout] = (ENV["TIMEOUT"] || "120").to_i

      queries = Vv::BrowserManager::BenchmarkQuery.order(:category, :name)
      queries = queries.by_category(category) if category

      if queries.empty?
        puts "No queries#{" for category '#{category}'" if category}. Run: rails vv:benchmark:seed"
        next
      end

      puts "Focus benchmark: #{model_list.join(', ')}"
      puts "Queries: #{queries.count}#{" (#{category})" if category}"
      puts "=" * 70

      model_list.each_with_index do |model, mi|
        model = model.sub(/:latest$/, "")
        puts "\n[#{mi + 1}/#{model_list.size}] #{model}"
        puts "-" * 40

        pass = 0
        queries.each_with_index do |query, qi|
          print "  [#{qi + 1}/#{queries.count}] #{query.name.ljust(40)} "
          $stdout.flush

          begin
            result = Vv::BrowserManager::Benchmark.run(
              query, model_id: model, model_category: "ollama", config: config
            )
            status = result.passed? ? "PASS" : "FAIL"
            lat = (result.latency_ms / 1000.0).round(1)
            puts format("%-6s %.2f  %ss", status, result.score || 0, lat)
            puts "         #{result.notes}" unless result.passed?
            pass += 1 if result.passed?
          rescue => e
            puts "ERROR  #{e.message[0..60]}"
          end
        end

        puts "  >> #{model}: #{pass}/#{queries.count} pass"
      end

      # Write focus.md with just these models
      path = File.join(DOCS_DIR, "focus.md")
      latest = latest_results
      focus_latest = latest.select { |_, r| model_list.include?(r.model_id) }

      md = []
      md << "# Benchmark Focus"
      md << ""
      md << "Generated: #{timestamp}"
      md << ""
      md << "Models: #{model_list.join(', ')}"
      md << "Queries: #{queries.count}#{" (category: #{category})" if category}"
      md << ""

      # Head-to-head table
      md << "## Head-to-Head"
      md << ""
      header = "| Query | Category |"
      sep    = "|-------|----------|"
      model_list.each { |m| header += " #{m} |"; sep += "------|" }
      md << header
      md << sep

      queries.each do |q|
        row = "| #{q.name} | #{q.category} |"
        model_list.each do |m|
          r = latest["#{m}:#{q.id}"]
          if r
            s = r.passed? ? "PASS" : "FAIL"
            row += " #{s} #{(r.latency_ms / 1000.0).round(1)}s |"
          else
            row += " — |"
          end
        end
        md << row
      end

      # Summary per model
      md << ""
      md << "## Summary"
      md << ""
      md << "| Model | Pass | Avg Score | Avg Latency | Fastest | Slowest |"
      md << "|-------|------|-----------|-------------|---------|---------|"
      model_list.each do |m|
        mr = queries.map { |q| latest["#{m}:#{q.id}"] }.compact
        next if mr.empty?
        pass = mr.count(&:passed?)
        avg_score = (mr.sum { |r| r.score || 0 }.to_f / mr.size).round(3)
        avg_lat = (mr.sum(&:latency_ms).to_f / mr.size / 1000).round(1)
        min_lat = (mr.map(&:latency_ms).min / 1000.0).round(1)
        max_lat = (mr.map(&:latency_ms).max / 1000.0).round(1)
        md << "| #{m} | #{pass}/#{mr.size} | #{avg_score} | #{avg_lat}s | #{min_lat}s | #{max_lat}s |"
      end

      # Category breakdown
      cats = queries.map(&:category).uniq
      if cats.size > 1
        md << ""
        md << "## By Category"
        md << ""
        cats.each do |cat|
          cat_qs = queries.where(category: cat)
          md << "### #{cat} (#{cat_qs.size} queries)"
          md << ""
          md << "| Model | Pass | Avg Latency | Avg Score |"
          md << "|-------|------|-------------|-----------|"
          model_list.each do |m|
            cr = cat_qs.map { |q| latest["#{m}:#{q.id}"] }.compact
            next if cr.empty?
            pass = cr.count(&:passed?)
            avg_lat = (cr.sum(&:latency_ms).to_f / cr.size / 1000).round(1)
            avg_score = (cr.sum { |r| r.score || 0 }.to_f / cr.size).round(3)
            md << "| #{m} | #{pass}/#{cr.size} | #{avg_lat}s | #{avg_score} |"
          end
          md << ""
        end
      end

      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, md.join("\n") + "\n")
      puts "\nWrote #{path} (#{md.size} lines)"
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

      grouped = scope.group_by(&:model_id)
      grouped.each do |mid, results|
        puts "\n== #{mid} =="
        puts format("  %-35s %-6s %-7s %-10s %s", "Query", "Status", "Score", "Latency", "Notes")
        puts "  " + "-" * 85

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

      # Also write markdown
      path = File.join(DOCS_DIR, "benchmark-results_#{today}.md")
      write_results_md(path)
    end

    desc "Run benchmarks via ActionCable pipeline (SERVER=url QUERY=name MODEL=id TIMEOUT=60)"
    task pipeline: :environment do
      require "net/http"
      require "json"

      server = ENV["SERVER"] || "http://localhost:3003"
      query_name = ENV["QUERY"]
      model_id = ENV["MODEL"]
      timeout = ENV["TIMEOUT"] || "60"

      uri = URI("#{server}/vv/benchmark/run")
      body = { timeout: timeout.to_i }
      body[:query_name] = query_name if query_name
      body[:model_id] = model_id if model_id

      puts "Running benchmarks via pipeline at #{server}..."
      puts "  Model: #{model_id || '(auto-detect from browser)'}"
      puts "  Query: #{query_name || '(all)'}"
      puts ""

      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = 600
      http.open_timeout = 5
      req = Net::HTTP::Post.new(uri.path, "Content-Type" => "application/json")
      req.body = body.to_json

      begin
        resp = http.request(req)
      rescue Errno::ECONNREFUSED
        puts "Cannot connect to #{server}. Is the server running?"
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
        puts format("  %-35s %-6s score=%.2f  latency=%dms",
          r["query"], status, r["score"] || 0, r["latency_ms"] || 0)
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
