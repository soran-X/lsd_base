class CreateReadersReports < ActiveRecord::Migration[8.1]
  def change
    create_table :readers_reports do |t|
      t.references :book,             null: false, foreign_key: true
      t.date        :report_date
      t.references  :reader,          null: true,  foreign_key: { to_table: :users }
      t.string      :sent_to
      t.text        :comments
      t.text        :film_commentary
      t.text        :synopsis
      t.integer     :publishing_recommended
      t.text        :publishing_recommendation
      t.integer     :film_recommended
      t.references  :reading_material, null: true,  foreign_key: true

      t.timestamps
    end
  end
end
