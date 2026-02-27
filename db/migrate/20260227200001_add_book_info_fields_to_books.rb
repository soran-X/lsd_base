class AddBookInfoFieldsToBooks < ActiveRecord::Migration[8.1]
  def change
    add_column :books, :old_title,          :string
    add_column :books, :lead_title,         :boolean, default: false, null: false
    add_column :books, :tracking_material,  :boolean, default: false, null: false
    add_column :books, :client_types,       :text, array: true, default: []

    remove_column :books, :genre_id, :integer
  end
end
