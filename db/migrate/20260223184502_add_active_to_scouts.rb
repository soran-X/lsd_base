class AddActiveToScouts < ActiveRecord::Migration[8.1]
  def change
    add_column :scouts, :active, :boolean
  end
end
