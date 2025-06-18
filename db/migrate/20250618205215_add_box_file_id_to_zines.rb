class AddBoxFileIdToZines < ActiveRecord::Migration[8.0]
  def change
    add_column :zines, :box_file_id, :string
    add_index :zines, :box_file_id, unique: true
  end
end
