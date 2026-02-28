class AddFieldsToContacts < ActiveRecord::Migration[8.1]
  def change
    add_column :contacts, :title,        :string
    add_column :contacts, :notes,        :text
    add_column :contacts, :discarded_at, :datetime
    add_reference :contacts, :company, foreign_key: true, null: true

    add_index :contacts, :discarded_at
  end
end
