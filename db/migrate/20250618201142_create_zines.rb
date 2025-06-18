class CreateZines < ActiveRecord::Migration[8.0]
  def change
    create_table :zines do |t|
      t.string :created_by
      t.references :category, null: false, foreign_key: true
      t.boolean :approved, default: false, null: false

      t.timestamps
    end

    add_index :zines, :approved
  end
end
