class AddFieldsToCompanies < ActiveRecord::Migration[8.1]
  def change
    add_reference :companies, :company_type, foreign_key: true, null: true

    add_column :companies, :address_line_1,      :string
    add_column :companies, :address_line_2,      :string
    add_column :companies, :city,                :string
    add_column :companies, :state,               :string
    add_column :companies, :postal_code,         :string
    add_column :companies, :phone,               :string
    add_column :companies, :fax,                 :string
    add_column :companies, :notes,               :text
    add_column :companies, :nest_subagents,      :boolean, default: false, null: false
    add_column :companies, :viewable_by_clients, :boolean, default: true,  null: false
    add_column :companies, :discarded_at,        :datetime

    remove_column :companies, :company_type, :string

    add_index :companies, :discarded_at
  end
end
