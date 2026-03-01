class CreateFilmGenres < ActiveRecord::Migration[8.1]
  def change
    create_table :film_genres do |t|
      t.string :name, null: false
      t.timestamps
    end
    add_index :film_genres, :name, unique: true
    add_index :film_genres, :name, name: "index_film_genres_on_name_trgm",
              opclass: :gin_trgm_ops, using: :gin
  end
end
