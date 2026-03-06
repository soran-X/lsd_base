class AddReportsSystem < ActiveRecord::Migration[8.1]
  def change
    # User ↔ ClientType
    create_table :user_client_types do |t|
      t.references :user,        null: false, foreign_key: true
      t.references :client_type, null: false, foreign_key: true
      t.timestamps
    end
    add_index :user_client_types, %i[user_id client_type_id], unique: true

    # Reports
    create_table :reports do |t|
      t.string  :title,            null: false
      t.text    :body
      t.text    :footer
      t.integer :report_type,      null: false, default: 0
      t.date    :report_date
      t.boolean :sent,             null: false, default: false
      t.boolean :pinned,           null: false, default: false
      t.text    :rendered_content
      t.references :created_by, foreign_key: { to_table: :users }, null: true
      t.timestamps
    end

    # Report ↔ ClientType
    create_table :report_client_types do |t|
      t.references :report,      null: false, foreign_key: true
      t.references :client_type, null: false, foreign_key: true
      t.timestamps
    end
    add_index :report_client_types, %i[report_id client_type_id], unique: true

    # Report ↔ Book (ordered)
    create_table :report_books do |t|
      t.references :report, null: false, foreign_key: true
      t.references :book,   null: false, foreign_key: true
      t.integer    :position, null: false, default: 0
      t.timestamps
    end
    add_index :report_books, %i[report_id book_id], unique: true
    add_index :report_books, %i[report_id position]
  end
end
