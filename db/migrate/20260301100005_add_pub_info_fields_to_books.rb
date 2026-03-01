class AddPubInfoFieldsToBooks < ActiveRecord::Migration[8.1]
  def change
    add_column :books, :confidential_material, :boolean, default: false, null: false
    add_column :books, :update_tagline, :string
  end
end
