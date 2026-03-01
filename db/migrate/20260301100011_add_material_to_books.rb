class AddMaterialToBooks < ActiveRecord::Migration[8.1]
  def change
    add_column :books, :material, :text
  end
end
