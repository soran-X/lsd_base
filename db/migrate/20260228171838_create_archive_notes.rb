class CreateArchiveNotes < ActiveRecord::Migration[8.1]
  def change
    create_table :archive_notes do |t|
      t.references :book, null: false, foreign_key: true
      t.text :note
      t.date :date

      t.timestamps
    end
  end
end
