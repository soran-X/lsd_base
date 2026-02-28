class CreateContactCompanies < ActiveRecord::Migration[8.1]
  def change
    create_table :contact_companies do |t|
      t.references :contact, null: false, foreign_key: true
      t.references :company, null: false, foreign_key: true

      t.timestamps
    end
    add_index :contact_companies, [:contact_id, :company_id], unique: true
  end
end
