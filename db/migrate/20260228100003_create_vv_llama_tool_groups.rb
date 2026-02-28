class CreateVvLlamaToolGroups < ActiveRecord::Migration[7.0]
  def change
    create_table :vv_llama_tool_groups, id: :string do |t|
      t.string :provider_id
      t.string :provider_resource_id
      t.string :toolgroup_type
      t.json :mcp_endpoint
      t.json :args, default: {}
      t.timestamps
    end
  end
end
