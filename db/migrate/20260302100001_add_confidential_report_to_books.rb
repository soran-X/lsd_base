class AddConfidentialReportToBooks < ActiveRecord::Migration[8.1]
  def change
    add_column :books, :confidential_report, :boolean, default: false, null: false
  end
end
