class TransformAuthorsTable < ActiveRecord::Migration[8.1]
  def up
    add_column :authors, :first_name, :string
    add_column :authors, :last_name,  :string

    # Migrate existing single-field name data.
    # Treats the last word as last_name, everything before as first_name.
    execute <<~SQL
      UPDATE authors
      SET
        last_name  = TRIM(REGEXP_REPLACE(name, '(.*)\s+(\S+)$', '\2')),
        first_name = TRIM(REGEXP_REPLACE(name, '(.*)\s+\S+$', '\1'))
      WHERE name IS NOT NULL AND name <> '' AND name LIKE '% %';

      UPDATE authors
      SET last_name = TRIM(name), first_name = ''
      WHERE name IS NOT NULL AND name <> '' AND name NOT LIKE '% %';
    SQL

    remove_column :authors, :name

    add_index :authors, :last_name
    add_index :authors, [:last_name, :first_name]
  end

  def down
    add_column :authors, :name, :string

    execute <<~SQL
      UPDATE authors
      SET name = TRIM(CONCAT(first_name, ' ', last_name))
    SQL

    remove_column :authors, :first_name
    remove_column :authors, :last_name
  end
end
