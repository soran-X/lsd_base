class MergeCreateUpdatePermissions < ActiveRecord::Migration[8.1]
  def up
    # Remove the now-redundant `create` and `update` permission rows.
    # role_permissions referencing them are deleted via the model's dependent: :destroy.
    Permission.where(action: %w[create update]).each(&:destroy)
  end

  def down
    # Restore removed permissions if rolling back.
    %w[books authors scouts roles].each do |resource|
      Permission.find_or_create_by!(resource: resource, action: "create")
      Permission.find_or_create_by!(resource: resource, action: "update")
    end
    Permission.find_or_create_by!(resource: "users",         action: "update")
    Permission.find_or_create_by!(resource: "site_settings", action: "update")
  end
end
