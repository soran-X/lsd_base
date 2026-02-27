class CreateBookAuthors < ActiveRecord::Migration[8.1]
  def change
    create_table :book_authors do |t|
      t.references :book,   null: false, foreign_key: true
      t.references :author, null: false, foreign_key: true
      t.integer    :role,   null: false, default: 0  # 0=author, 1=translator

      t.timestamps
    end

    # A given author can only hold one role per book (no duplicate author+role pairs)
    add_index :book_authors, [:book_id, :author_id, :role], unique: true
  end
end
