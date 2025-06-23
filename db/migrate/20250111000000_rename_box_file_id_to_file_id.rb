class RenameBoxFileIdToFileId < ActiveRecord::Migration[8.0]
  def change
    rename_column :zines, :box_file_id, :file_id
  end
end