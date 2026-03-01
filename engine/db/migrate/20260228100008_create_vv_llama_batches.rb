class CreateVvLlamaBatches < ActiveRecord::Migration[7.0]
  def change
    create_table :vv_llama_batches, id: :string do |t|
      t.string :input_file_id
      t.string :endpoint
      t.string :status, default: "validating"
      t.string :output_file_id
      t.string :error_file_id
      t.json :request_counts, default: { total: 0, completed: 0, failed: 0 }
      t.json :metadata, default: {}
      t.datetime :completed_at
      t.timestamps
    end
  end
end
