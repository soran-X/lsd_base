class AddBookTracking < ActiveRecord::Migration[8.1]
  def up
    add_reference :books, :last_updated_by, foreign_key: { to_table: :users }, null: true
    add_index :books, :updated_at
  end

  def down
    remove_index :books, :updated_at
    remove_reference :books, :last_updated_by, foreign_key: { to_table: :users }
  end
end
