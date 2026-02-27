class CreateClientTypes < ActiveRecord::Migration[8.1]
  DEFAULT_CLIENT_TYPES = %w[International US UK ANZ Audio Film].freeze

  def change
    create_table :client_types do |t|
      t.string :name, null: false
      t.timestamps
    end
    add_index :client_types, :name, unique: true

    create_table :book_client_types do |t|
      t.references :book,        null: false, foreign_key: true
      t.references :client_type, null: false, foreign_key: true
      t.timestamps
    end
    add_index :book_client_types, [:book_id, :client_type_id], unique: true

    # Seed defaults
    reversible do |dir|
      dir.up do
        now = Time.current.strftime("%Y-%m-%d %H:%M:%S")
        DEFAULT_CLIENT_TYPES.each do |name|
          execute "INSERT INTO client_types (name, created_at, updated_at) VALUES ('#{name}', '#{now}', '#{now}')"
        end
      end
    end

    remove_column :books, :client_types, :text, array: true, default: []
  end
end
