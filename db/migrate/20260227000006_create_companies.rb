class CreateCompanies < ActiveRecord::Migration[8.1]
  def change
    create_table :companies do |t|
      t.string :name,         null: false
      t.string :company_type
      t.string :website
      t.string :country

      t.timestamps
    end

    add_index :companies, :name
  end
end
