class RemoveScoutsAndSeedData < ActiveRecord::Migration[8.1]
  DEFAULT_SUBGENRES = %w[
    Alternate\ History Cozy\ Mystery Cyberpunk Dark\ Fantasy Domestic\ Noir
    Dystopian Epic\ Fantasy Gothic Hard-Boiled High\ Fantasy Historical
    Legal\ Thriller Magical\ Realism Medical\ Thriller Noir Paranormal
    Psychological\ Thriller Regency Space\ Opera Spy\ /\ Espionage Steampunk
    Supernatural Urban\ Fantasy
  ].freeze

  def up
    drop_table :scouts

    # Seed Scout role (between Admin:50 and Client:10)
    now = Time.current.strftime("%Y-%m-%d %H:%M:%S")
    execute <<~SQL
      INSERT INTO roles (name, hierarchy_level, created_at, updated_at)
      VALUES ('Scout', 25, '#{now}', '#{now}')
      ON CONFLICT (name) DO NOTHING
    SQL

    # Seed default subgenres
    DEFAULT_SUBGENRES.each do |name|
      sanitized = name.gsub("'", "''")
      execute <<~SQL
        INSERT INTO sub_genres (name, created_at, updated_at)
        VALUES ('#{sanitized}', '#{now}', '#{now}')
        ON CONFLICT (name) DO NOTHING
      SQL
    end
  end

  def down
    create_table :scouts do |t|
      t.string  :name
      t.string  :specialty
      t.text    :notes
      t.boolean :active
      t.datetime :discarded_at
      t.timestamps
    end
    add_index :scouts, :discarded_at

    execute "DELETE FROM roles WHERE name = 'Scout'"
    execute "DELETE FROM sub_genres WHERE name IN (#{DEFAULT_SUBGENRES.map { |n| "'#{n.gsub("'", "''")}'" }.join(', ')})"
  end
end
