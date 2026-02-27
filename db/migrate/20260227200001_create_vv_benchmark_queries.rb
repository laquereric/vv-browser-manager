class CreateVvBenchmarkQueries < ActiveRecord::Migration[7.1]
  def change
    create_table :vv_benchmark_queries do |t|
      t.string  :name,            null: false
      t.string  :category,        null: false
      t.text    :system_prompt,   null: false
      t.text    :user_prompt,     null: false
      t.string  :expected_format, null: false, default: "json"
      t.json    :expected_keys,   default: []
      t.json    :metadata,        default: {}
      t.timestamps
    end

    add_index :vv_benchmark_queries, :name, unique: true
    add_index :vv_benchmark_queries, :category
  end
end
