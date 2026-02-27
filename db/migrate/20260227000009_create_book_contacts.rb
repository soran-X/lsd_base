class CreateBookContacts < ActiveRecord::Migration[8.1]
  def change
    create_table :book_contacts do |t|
      t.references :book,    null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true
      # 0=editor, 1=agent, 2=film_agent, 3=author_contact, 4=other
      t.integer    :role,    null: false, default: 0

      t.timestamps
    end

    add_index :book_contacts, [:book_id, :contact_id, :role], unique: true
  end
end
