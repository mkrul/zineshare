class AddPendingModerationToZines < ActiveRecord::Migration[8.0]
  def change
    add_column :zines, :pending_moderation, :boolean, default: false, null: false
  end
end
