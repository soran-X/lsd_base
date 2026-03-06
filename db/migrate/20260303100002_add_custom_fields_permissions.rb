class AddCustomFieldsPermissions < ActiveRecord::Migration[8.0]
  def up
    # Sync any new permission rows created by the updated ALL_PERMISSIONS constant
    Permission.sync_all!

    # Assign all custom_fields permissions to every role with hierarchy_level >= 50
    custom_field_perms = Permission.where(resource: "custom_fields")
    Role.where("hierarchy_level >= 50").each do |role|
      custom_field_perms.each do |perm|
        RolePermission.find_or_create_by!(role: role, permission: perm)
      end
    end
  end

  def down
    Permission.where(resource: "custom_fields").each do |perm|
      perm.role_permissions.destroy_all
      perm.destroy
    end
  end
end
