class CreateVvLlamaVectorStoreFiles < ActiveRecord::Migration[7.0]
  def change
    create_table :vv_llama_vector_store_files, id: :string do |t|
      t.string :vector_store_id
      t.string :file_id
      t.string :status, default: "in_progress"
      t.json :chunking_strategy
      t.timestamps
    end

    add_index :vv_llama_vector_store_files, :vector_store_id
    add_index :vv_llama_vector_store_files, :file_id
  end
end
