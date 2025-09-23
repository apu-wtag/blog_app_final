class AddArchivedAtToArticles < ActiveRecord::Migration[8.0]
  def change
    add_column :articles, :archived_at, :datetime
    add_index :articles, :archived_at
  end
end
