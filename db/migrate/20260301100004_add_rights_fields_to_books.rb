class AddRightsFieldsToBooks < ActiveRecord::Migration[8.1]
  def change
    add_column :books, :rights_sold, :text
    add_column :books, :log_line, :text
    add_column :books, :pub_info, :text
  end
end
