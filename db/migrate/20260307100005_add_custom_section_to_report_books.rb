class AddCustomSectionToReportBooks < ActiveRecord::Migration[8.0]
  def change
    add_column :report_books, :custom_section, :string
  end
end
