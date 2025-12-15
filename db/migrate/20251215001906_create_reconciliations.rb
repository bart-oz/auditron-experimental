class CreateReconciliations < ActiveRecord::Migration[8.1]
  def change
    create_table :reconciliations, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.integer :status, null: false, default: 0
      t.integer :bank_only_count, default: 0
      t.integer :processor_only_count, default: 0
      t.integer :matched_count, default: 0
      t.integer :discrepancy_count, default: 0
      t.text :report
      t.text :error_message
      t.datetime :processed_at

      t.timestamps
    end

    add_index :reconciliations, [:user_id, :status]
    add_index :reconciliations, [:user_id, :created_at]
  end
end
