class AddExtendedFieldsToContacts < ActiveRecord::Migration[8.1]
  def change
    add_column :contacts, :assistant_name,  :string
    add_column :contacts, :address_line_1,  :string
    add_column :contacts, :address_line_2,  :string
    add_column :contacts, :city,            :string
    add_column :contacts, :state,           :string
    add_column :contacts, :country,         :string
    add_column :contacts, :zip,             :string
    add_column :contacts, :direct_number,   :string
    add_column :contacts, :mobile_number,   :string
    add_column :contacts, :home_number,     :string
    add_column :contacts, :fax_number,      :string
    add_reference :contacts, :tracked_by, foreign_key: { to_table: :users }, null: true
  end
end
