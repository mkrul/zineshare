class AddUserToZines < ActiveRecord::Migration[8.0]
  def change
    add_reference :zines, :user, null: true, foreign_key: true
  end
end
