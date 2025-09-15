class CreateReports < ActiveRecord::Migration[8.0]
  def change
    create_table :reports do |t|
      t.references :user, null: false, foreign_key: true
      t.text :reason
      t.integer :status

      t.timestamps
    end
    add_index :reports, :status
  end
end
