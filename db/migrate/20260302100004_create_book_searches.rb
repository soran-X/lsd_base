class CreateBookSearches < ActiveRecord::Migration[8.1]
  def change
    create_table :book_searches do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.jsonb :params, null: false, default: {}
      t.timestamps
    end

    add_index :book_searches, [:user_id, :created_at]
  end
end
