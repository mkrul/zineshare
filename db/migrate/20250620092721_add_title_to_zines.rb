class AddTitleToZines < ActiveRecord::Migration[8.0]
  def change
    add_column :zines, :title, :string
  end
end
