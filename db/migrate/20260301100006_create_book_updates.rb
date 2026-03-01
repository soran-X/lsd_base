class CreateBookUpdates < ActiveRecord::Migration[8.1]
  def change
    create_table :book_updates do |t|
      t.references :book, null: false, foreign_key: true
      t.text :content

      t.timestamps
    end
  end
end
