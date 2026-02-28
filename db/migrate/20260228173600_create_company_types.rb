class CreateCompanyTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :company_types do |t|
      t.string :name, null: false
      t.timestamps
    end

    add_index :company_types, :name, unique: true
  end
end
