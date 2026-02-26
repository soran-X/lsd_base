class CreateBooks < ActiveRecord::Migration[8.1]
  def change
    create_table :books do |t|
      t.string :title
      t.integer :author_id
      t.text :description
      t.date :published_at

      t.timestamps
    end
  end
end
