class AddDiscardToBooks < ActiveRecord::Migration[8.1]
  def change
    add_column :books, :discarded_at, :datetime
    add_index :books, :discarded_at
  end
end
