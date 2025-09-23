class CreateModerationRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :moderation_records do |t|
      t.references :article, null: false, foreign_key: true
      t.references :admin, null: false, foreign_key: { to_table: :users }
      t.text :admin_reason
      t.text :author_note
      t.integer :status, default: 0

      t.timestamps
    end
    add_index :moderation_records, :status
  end
end
