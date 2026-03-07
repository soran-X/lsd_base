class CreateCustomReportTemplateFields < ActiveRecord::Migration[8.0]
  def change
    create_table :custom_report_template_fields do |t|
      t.references :custom_report_template, null: false, foreign_key: true
      t.string  :field_key, null: false
      t.integer :position, default: 0
      t.timestamps
    end
  end
end
