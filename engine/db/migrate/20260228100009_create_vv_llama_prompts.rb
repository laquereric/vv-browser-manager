class CreateVvLlamaPrompts < ActiveRecord::Migration[7.0]
  def change
    create_table :vv_llama_prompts, id: :string do |t|
      t.string :name
      t.text :description
      t.json :metadata, default: {}
      t.timestamps
    end

    create_table :vv_llama_prompt_versions do |t|
      t.string :prompt_id
      t.integer :version, default: 1
      t.text :template
      t.json :variables, default: []
      t.timestamps
    end

    add_index :vv_llama_prompt_versions, [:prompt_id, :version], unique: true
  end
end
