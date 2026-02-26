class CreateScouts < ActiveRecord::Migration[8.1]
  def change
    create_table :scouts do |t|
      t.string :name
      t.string :specialty
      t.text :notes

      t.timestamps
    end
  end
end
