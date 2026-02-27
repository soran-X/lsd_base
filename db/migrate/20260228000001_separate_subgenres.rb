class SeparateSubgenres < ActiveRecord::Migration[8.1]
  def up
    # Drop the self-referential parent link from genres
    remove_foreign_key :genres, column: :parent_id
    remove_column :genres, :parent_id

    # Standalone sub_genres table
    create_table :sub_genres do |t|
      t.string :name, null: false
      t.timestamps
    end
    add_index :sub_genres, :name, unique: true

    # Join table: books ↔ sub_genres
    create_table :book_sub_genres do |t|
      t.references :book,      null: false, foreign_key: true
      t.references :sub_genre, null: false, foreign_key: true
      t.timestamps
    end
    add_index :book_sub_genres, [:book_id, :sub_genre_id], unique: true
  end

  def down
    drop_table :book_sub_genres
    drop_table :sub_genres
    add_reference :genres, :parent, foreign_key: { to_table: :genres }, null: true
  end
end
