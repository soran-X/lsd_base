class CreateFilmTrackingGenres < ActiveRecord::Migration[8.1]
  def change
    create_table :film_tracking_genres do |t|
      t.references :film_tracking, null: false, foreign_key: true
      t.references :film_genre,    null: false, foreign_key: true
      t.timestamps
    end
    add_index :film_tracking_genres, [:film_tracking_id, :film_genre_id], unique: true,
              name: "index_film_tracking_genres_unique"
  end
end
