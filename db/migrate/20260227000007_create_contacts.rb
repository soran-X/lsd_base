class CreateContacts < ActiveRecord::Migration[8.1]
  def change
    create_table :contacts do |t|
      t.string :first_name, null: false
      t.string :last_name,  null: false
      t.string :email
      t.string :phone

      t.timestamps
    end

    add_index :contacts, [:last_name, :first_name]
  end
end
