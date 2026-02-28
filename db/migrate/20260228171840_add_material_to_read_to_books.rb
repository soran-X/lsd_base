class AddMaterialToReadToBooks < ActiveRecord::Migration[8.1]
  def change
    add_column :books, :material_to_read, :boolean, default: false, null: false
  end
end
