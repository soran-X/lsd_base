class CreateTerritories < ActiveRecord::Migration[8.0]
  def change
    create_table :territories do |t|
      t.string :name, null: false
      t.timestamps
    end
    add_index :territories, :name, unique: true
  end
end
