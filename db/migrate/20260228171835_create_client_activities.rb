class CreateClientActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :client_activities do |t|
      t.references :book, null: false, foreign_key: true
      t.date :date
      t.string :activity_type
      t.bigint :company_id
      t.bigint :contact_id
      t.text :content

      t.timestamps
    end
  end
end
