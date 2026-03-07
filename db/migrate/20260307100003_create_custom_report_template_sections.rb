class CreateCustomReportTemplateSections < ActiveRecord::Migration[8.0]
  def change
    create_table :custom_report_template_sections do |t|
      t.references :custom_report_template, null: false, foreign_key: true
      t.string  :name, null: false
      t.integer :position, default: 0
      t.timestamps
    end
  end
end
