class CreateFilmTrackings < ActiveRecord::Migration[8.1]
  def change
    create_table :film_trackings do |t|
      t.references :book, null: false, foreign_key: true, index: { unique: true }
      t.text   :film_synopsis
      t.string :film_option
      t.text   :readers_thoughts
      t.string :category

      t.timestamps
    end
  end
end
