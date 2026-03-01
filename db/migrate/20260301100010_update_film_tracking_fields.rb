class UpdateFilmTrackingFields < ActiveRecord::Migration[8.1]
  def change
    change_column :film_trackings, :film_option, :text
    add_column    :film_trackings, :film_option_date, :date
    add_column    :film_trackings, :comments,         :text
    add_column    :film_trackings, :material,         :text
    add_column    :film_trackings, :off,              :boolean, default: false, null: false
    add_column    :film_trackings, :pub_buzz,         :boolean, default: false, null: false
  end
end
