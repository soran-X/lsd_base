class CreateBookCompanies < ActiveRecord::Migration[8.1]
  def change
    create_table :book_companies do |t|
      t.references :book,    null: false, foreign_key: true
      t.references :company, null: false, foreign_key: true
      # 0=publisher, 1=agency, 2=film_agency, 3=distributor, 4=other
      t.integer    :role,    null: false, default: 0

      t.timestamps
    end

    add_index :book_companies, [:book_id, :company_id, :role], unique: true
  end
end
