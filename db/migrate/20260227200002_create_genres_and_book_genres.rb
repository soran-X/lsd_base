class CreateGenresAndBookGenres < ActiveRecord::Migration[8.1]
  DEFAULT_GENRES = [
    "Biography / Memoir", "Business", "Children's", "Commercial Fiction",
    "Crime / Thriller", "Fantasy", "Graphic Novel", "History", "Horror",
    "Literary Fiction", "Non-Fiction", "Poetry", "Romance",
    "Science Fiction", "Self-Help", "Short Stories", "Young Adult", "Other"
  ].freeze

  def change
    create_table :genres do |t|
      t.string :name, null: false
      t.timestamps
    end
    add_index :genres, :name, unique: true

    create_table :book_genres do |t|
      t.references :book,  null: false, foreign_key: true
      t.references :genre, null: false, foreign_key: true
      t.timestamps
    end
    add_index :book_genres, [:book_id, :genre_id], unique: true

    reversible do |dir|
      dir.up do
        now = Time.current.strftime("%Y-%m-%d %H:%M:%S")
        DEFAULT_GENRES.each do |name|
          sanitized = name.gsub("'", "''")
          execute "INSERT INTO genres (name, created_at, updated_at) VALUES ('#{sanitized}', '#{now}', '#{now}')"
        end
      end
    end
  end
end
