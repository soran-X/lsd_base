class AddIndexes < ActiveRecord::Migration[8.1]
  def change
    add_index :users, :provider
    add_index :users, :uid
    add_index :users, :approved
    add_index :books, :author_id
    add_index :books, :published_at
  end
end
