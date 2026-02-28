class MigrateContactCompanyId < ActiveRecord::Migration[8.1]
  def up
    # Copy existing company_id values into the join table, skip duplicates
    execute <<~SQL
      INSERT INTO contact_companies (contact_id, company_id, created_at, updated_at)
      SELECT id, company_id, NOW(), NOW()
      FROM contacts
      WHERE company_id IS NOT NULL
      ON CONFLICT (contact_id, company_id) DO NOTHING
    SQL
    remove_reference :contacts, :company, foreign_key: true, null: true
  end

  def down
    add_reference :contacts, :company, foreign_key: true, null: true
    execute <<~SQL
      UPDATE contacts c
      SET company_id = (
        SELECT company_id FROM contact_companies cc
        WHERE cc.contact_id = c.id
        ORDER BY cc.created_at
        LIMIT 1
      )
    SQL
  end
end
