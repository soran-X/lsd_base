class AddBookSearch < ActiveRecord::Migration[8.1]
  def up
    add_column :books, :synopsis_plain, :text

    # Populate from existing synopses by stripping HTML tags
    execute <<~SQL
      UPDATE books
      SET synopsis_plain = trim(regexp_replace(
        regexp_replace(synopsis, '<[^>]+>', ' ', 'g'),
        '\s+', ' ', 'g'
      ))
      WHERE synopsis IS NOT NULL AND synopsis <> ''
    SQL

    # GIN trigram indexes for fast similarity search
    execute "CREATE INDEX index_books_on_title_trgm ON books USING gin (title gin_trgm_ops)"
    execute "CREATE INDEX index_books_on_synopsis_plain_trgm ON books USING gin (synopsis_plain gin_trgm_ops)"
  end

  def down
    execute "DROP INDEX IF EXISTS index_books_on_title_trgm"
    execute "DROP INDEX IF EXISTS index_books_on_synopsis_plain_trgm"
    remove_column :books, :synopsis_plain
  end
end
