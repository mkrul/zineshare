class RemoveApprovedFromZines < ActiveRecord::Migration[8.0]
  def change
    remove_index :zines, :approved
    remove_column :zines, :approved, :boolean
  end
end
