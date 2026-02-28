class CreateBookMemos < ActiveRecord::Migration[8.1]
  def change
    create_table :book_memos do |t|
      t.references :book, null: false, foreign_key: true
      t.text :note
      t.date :date

      t.timestamps
    end
  end
end
