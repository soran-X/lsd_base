class AddTrigramIndexToAuthors < ActiveRecord::Migration[8.1]
  def up
    # GIN trigram index on the "Last, First" display format for fast fuzzy search
    execute <<~SQL
      CREATE INDEX index_authors_on_name_trgm
      ON authors
      USING gin (
        (TRIM(last_name) || ', ' || TRIM(COALESCE(first_name, ''))) gin_trgm_ops
      );
    SQL
  end

  def down
    execute "DROP INDEX IF EXISTS index_authors_on_name_trgm;"
  end
end
