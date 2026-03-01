class AddPlainColumnsToBooks < ActiveRecord::Migration[8.1]
  def up
    add_column :books, :material_plain,    :text
    add_column :books, :pub_info_plain,    :text
    add_column :books, :log_line_plain,    :text
    add_column :books, :notes_plain,       :text
    add_column :books, :rights_sold_plain, :text

    add_index :books, :material_plain,    using: :gin, opclass: :gin_trgm_ops,
              name: "index_books_on_material_plain_trgm"
    add_index :books, :pub_info_plain,    using: :gin, opclass: :gin_trgm_ops,
              name: "index_books_on_pub_info_plain_trgm"
    add_index :books, :log_line_plain,    using: :gin, opclass: :gin_trgm_ops,
              name: "index_books_on_log_line_plain_trgm"
    add_index :books, :notes_plain,       using: :gin, opclass: :gin_trgm_ops,
              name: "index_books_on_notes_plain_trgm"
    add_index :books, :rights_sold_plain, using: :gin, opclass: :gin_trgm_ops,
              name: "index_books_on_rights_sold_plain_trgm"

    # Backfill existing rows
    Book.find_each { |b| b.save(touch: false) }
  end

  def down
    remove_index :books, name: "index_books_on_material_plain_trgm"
    remove_index :books, name: "index_books_on_pub_info_plain_trgm"
    remove_index :books, name: "index_books_on_log_line_plain_trgm"
    remove_index :books, name: "index_books_on_notes_plain_trgm"
    remove_index :books, name: "index_books_on_rights_sold_plain_trgm"

    remove_column :books, :material_plain
    remove_column :books, :pub_info_plain
    remove_column :books, :log_line_plain
    remove_column :books, :notes_plain
    remove_column :books, :rights_sold_plain
  end
end
