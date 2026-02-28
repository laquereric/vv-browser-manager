class CreateVvLlamaFiles < ActiveRecord::Migration[7.0]
  def change
    create_table :vv_llama_files, id: :string do |t|
      t.string :filename
      t.string :purpose, default: "assistants"
      t.integer :bytes, default: 0
      t.string :mime_type
      t.string :storage_path
      t.string :status, default: "uploaded"
      t.timestamps
    end
  end
end
