class CreateVvLlamaScoringFunctions < ActiveRecord::Migration[7.0]
  def change
    create_table :vv_llama_scoring_functions, id: :string do |t|
      t.text :description
      t.string :return_type, default: "float"
      t.json :params, default: {}
      t.string :provider_id
      t.timestamps
    end
  end
end
