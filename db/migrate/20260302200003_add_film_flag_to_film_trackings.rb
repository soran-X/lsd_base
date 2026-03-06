class AddFilmFlagToFilmTrackings < ActiveRecord::Migration[8.1]
  def change
    add_column :film_trackings, :film_flag, :string
  end
end
