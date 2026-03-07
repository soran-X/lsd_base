class AddCustomReportTemplatesPermissions < ActiveRecord::Migration[8.0]
  def up
    actions = %w[index show new edit destroy]

    actions.each do |action|
      perm = Permission.find_or_create_by!(action: action, resource: "custom_report_templates")

      %w[SuperAdmin Admin].each do |role_name|
        role = Role.find_by(name: role_name)
        next unless role
        RolePermission.find_or_create_by!(role: role, permission: perm)
      end
    end
  end

  def down
    perm_ids = Permission.where(resource: "custom_report_templates").pluck(:id)
    RolePermission.where(permission_id: perm_ids).delete_all
    Permission.where(id: perm_ids).delete_all
  end
end
