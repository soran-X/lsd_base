class CreateCustomReportTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :custom_report_templates do |t|
      t.string :name, null: false
      t.references :created_by, foreign_key: { to_table: :users }, null: true
      t.timestamps
    end

    add_index :custom_report_templates, :name, unique: true
  end
end
