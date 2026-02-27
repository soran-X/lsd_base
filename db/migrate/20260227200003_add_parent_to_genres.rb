class AddParentToGenres < ActiveRecord::Migration[8.1]
  def change
    add_reference :genres, :parent, foreign_key: { to_table: :genres }, null: true
  end
end
