class TransformBooksTable < ActiveRecord::Migration[8.1]
  def up
    # Drop the old direct author FK (replaced by book_authors join table)
    remove_index  :books, :author_id
    remove_column :books, :author_id, :integer

    # Drop the old date field (replaced by publication_year + publication_season)
    remove_index  :books, :published_at
    remove_column :books, :published_at, :date

    # Rename description → synopsis
    rename_column :books, :description, :synopsis

    # Convert status from string enum → integer enum
    # (draft=0, active=1, inactive=2)
    add_column :books, :status_int, :integer, default: 0, null: false
    execute <<~SQL
      UPDATE books
      SET status_int = CASE status
        WHEN 'draft'     THEN 0
        WHEN 'active'    THEN 1
        WHEN 'inactive'  THEN 2
        ELSE 0
      END
    SQL
    remove_column :books, :status, :string
    rename_column :books, :status_int, :status

    # New fields
    add_column :books, :subtitle,            :string
    add_column :books, :publication_year,    :integer
    add_column :books, :publication_season,  :string
    add_column :books, :confidential,        :boolean, default: false, null: false

    add_reference :books, :primary_scout,
                  foreign_key: { to_table: :users },
                  null: true,
                  index: true

    add_reference :books, :secondary_scout,
                  foreign_key: { to_table: :users },
                  null: true,
                  index: true

    # genre_id — no Genre model yet, bare column without FK
    add_column :books, :genre_id, :integer
    add_index  :books, :genre_id

    add_index :books, :status
    add_index :books, :publication_year
    add_index :books, :confidential
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
      "Cannot safely reverse the books schema transformation without data loss."
  end
end
