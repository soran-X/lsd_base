class CreateFilmActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :film_activities do |t|
      t.references :book, null: false, foreign_key: true
      t.date   :date
      t.string :client
      t.text   :notes
      t.timestamps
    end
  end
end
