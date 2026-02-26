class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      t.references :user, null: true, foreign_key: true
      t.string :action, null: false
      t.string :resource_type, null: false
      t.integer :resource_id
      t.jsonb :metadata, default: {}
      t.string :ip_address

      t.timestamps
    end

    add_index :audit_logs, :created_at
  end
end
