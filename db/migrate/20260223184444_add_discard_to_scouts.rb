class AddDiscardToScouts < ActiveRecord::Migration[8.1]
  def change
    add_column :scouts, :discarded_at, :datetime
    add_index :scouts, :discarded_at
  end
end
