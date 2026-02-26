class AddDiscardToAuthors < ActiveRecord::Migration[8.1]
  def change
    add_column :authors, :discarded_at, :datetime
    add_index :authors, :discarded_at
  end
end
