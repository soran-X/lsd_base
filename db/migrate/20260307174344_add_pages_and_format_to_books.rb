class AddPagesAndFormatToBooks < ActiveRecord::Migration[8.1]
  def change
    add_column :books, :pages, :integer
    add_column :books, :format, :string
  end
end
