class CreateVvLlamaTools < ActiveRecord::Migration[7.0]
  def change
    create_table :vv_llama_tools, id: :string do |t|
      t.string :tool_group_id
      t.text :description
      t.json :parameters, default: {}
      t.json :metadata, default: {}
      t.timestamps
    end

    add_index :vv_llama_tools, :tool_group_id
  end
end
