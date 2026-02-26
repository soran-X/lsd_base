class AddFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :role, foreign_key: true, index: true
    add_column :users, :approved, :boolean, null: false, default: false
  end
end
