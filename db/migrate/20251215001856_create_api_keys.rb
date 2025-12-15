class CreateApiKeys < ActiveRecord::Migration[8.1]
  def change
    create_table :api_keys, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :token_digest
      t.string :name
      t.datetime :last_used_at
      t.datetime :expires_at

      t.timestamps
    end
    add_index :api_keys, :token_digest, unique: true
  end
end
