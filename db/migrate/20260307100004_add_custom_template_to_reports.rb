class AddCustomTemplateToReports < ActiveRecord::Migration[8.0]
  def change
    add_reference :reports, :custom_report_template, null: true, foreign_key: true
  end
end
