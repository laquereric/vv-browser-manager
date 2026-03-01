class CreateVvBenchmarkResults < ActiveRecord::Migration[7.1]
  def change
    create_table :vv_benchmark_results do |t|
      t.references :benchmark_query, null: false, foreign_key: { to_table: :vv_benchmark_queries }
      t.string  :model_id,       null: false
      t.string  :model_category
      t.text    :response
      t.integer :latency_ms
      t.integer :input_tokens
      t.integer :output_tokens
      t.boolean :format_valid,   default: false
      t.boolean :keys_present,   default: false
      t.float   :score
      t.text    :notes
      t.json    :config,         default: {}
      t.timestamps
    end

    add_index :vv_benchmark_results, :model_id
    add_index :vv_benchmark_results, :model_category
    add_index :vv_benchmark_results, [:benchmark_query_id, :model_id]
  end
end
