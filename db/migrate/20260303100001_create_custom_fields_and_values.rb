class CreateCustomFieldsAndValues < ActiveRecord::Migration[8.0]
  def change
    create_table :custom_fields do |t|
      t.string  :name,       null: false
      t.string  :group_name, null: false
      t.integer :field_type, null: false
      t.integer :position,   default: 0
      t.jsonb   :choices,    default: []
      t.boolean :required,   default: false
      t.boolean :active,     default: true
      t.timestamps
    end

    create_table :custom_field_values do |t|
      t.references :book,         null: false, foreign_key: true
      t.references :custom_field, null: false, foreign_key: true
      t.jsonb :value_json
      t.timestamps
    end

    add_index :custom_field_values, [:book_id, :custom_field_id], unique: true
  end
end
