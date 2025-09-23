class AddRejectionReasonToModerationRecords < ActiveRecord::Migration[8.0]
  def change
    add_column :moderation_records, :rejection_reason, :text
  end
end
