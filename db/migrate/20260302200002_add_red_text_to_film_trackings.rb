class AddRedTextToFilmTrackings < ActiveRecord::Migration[8.1]
  def change
    add_column :film_trackings, :enable_red_text, :boolean, default: false, null: false
    add_column :film_trackings, :red_text, :text
  end
end
