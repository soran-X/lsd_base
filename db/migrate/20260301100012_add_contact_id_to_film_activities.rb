class AddContactIdToFilmActivities < ActiveRecord::Migration[8.1]
  def change
    add_reference :film_activities, :contact, null: true, foreign_key: true
  end
end
