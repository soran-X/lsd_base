class AddScheduleAndNotesToBooks < ActiveRecord::Migration[8.1]
  def change
    add_column :books, :delivery_date,   :date
    add_column :books, :followup_date,   :date
    add_column :books, :notes,           :text
    add_column :books, :readers_report,  :text
  end
end
