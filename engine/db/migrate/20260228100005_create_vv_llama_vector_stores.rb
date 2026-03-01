class CreateVvLlamaVectorStores < ActiveRecord::Migration[7.0]
  def change
    create_table :vv_llama_vector_stores, id: :string do |t|
      t.string :name
      t.string :embedding_model
      t.integer :embedding_dimension
      t.string :status, default: "completed"
      t.integer :usage_bytes, default: 0
      t.json :chunking_strategy
      t.json :file_counts, default: { in_progress: 0, completed: 0, failed: 0, cancelled: 0, total: 0 }
      t.json :metadata, default: {}
      t.datetime :expires_at
      t.timestamps
    end
  end
end
