class CreateVvLlamaShields < ActiveRecord::Migration[7.0]
  def change
    create_table :vv_llama_shields, id: :string do |t|
      t.string :provider_id
      t.string :provider_shield_id
      t.string :shield_type
      t.json :params, default: {}
      t.timestamps
    end
  end
end
