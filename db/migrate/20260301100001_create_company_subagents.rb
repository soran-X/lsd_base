class CreateCompanySubagents < ActiveRecord::Migration[8.0]
  def change
    create_table :company_subagents do |t|
      t.references :company,           null: false, foreign_key: true
      t.references :subagent_company,  null: false, foreign_key: { to_table: :companies }
      t.references :territory,         null: true,  foreign_key: true
      t.timestamps
    end
  end
end
