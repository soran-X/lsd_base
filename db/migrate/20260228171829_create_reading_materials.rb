class CreateReadingMaterials < ActiveRecord::Migration[8.1]
  def change
    create_table :reading_materials do |t|
      t.references :book, null: false, foreign_key: true
      t.string :material
      t.string :reader
      t.integer :number_of_pages
      t.date :date

      t.timestamps
    end
  end
end
