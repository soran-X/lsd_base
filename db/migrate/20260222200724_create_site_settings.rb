class CreateSiteSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :site_settings do |t|
      t.string :key
      t.text :value

      t.timestamps
    end
    add_index :site_settings, :key, unique: true
  end
end
