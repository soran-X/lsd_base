# ===========================================================================
# Roles
# ===========================================================================
superadmin_role = Role.find_or_create_by!(name: "SuperAdmin") { |r| r.hierarchy_level = 100 }
admin_role      = Role.find_or_create_by!(name: "Admin")      { |r| r.hierarchy_level = 50 }
client_role     = Role.find_or_create_by!(name: "Client")     { |r| r.hierarchy_level = 10 }

puts "Roles seeded: #{Role.pluck(:name).join(', ')}"

# ===========================================================================
# Site Settings
# ===========================================================================
SiteSetting.find_or_create_by!(key: "allow_public_signup") { |s| s.value = "true" }
SiteSetting.find_or_create_by!(key: "app_name")           { |s| s.value = "ClinicDev" }
SiteSetting.find_or_create_by!(key: "primary_color")      { |s| s.value = "#4f46e5" }
SiteSetting.find_or_create_by!(key: "secondary_color")    { |s| s.value = "#111827" }
SiteSetting.find_or_create_by!(key: "tertiary_color")     { |s| s.value = "#6366f1" }
SiteSetting.find_or_create_by!(key: "app_logo")           { |s| s.value = "0" }
SiteSetting.find_or_create_by!(key: "favicon_icon")       { |s| s.value = "0" }

puts "SiteSettings seeded"

# ===========================================================================
# Permissions — seed all entries from ALL_PERMISSIONS constant
# ===========================================================================
Permission::ALL_PERMISSIONS.each do |resource, actions|
  actions.each do |action|
    Permission.find_or_create_by!(resource: resource, action: action)
  end
end

puts "Permissions seeded: #{Permission.count}"

# ===========================================================================
# Role Permission assignments
# ===========================================================================
all_permissions   = Permission.all.to_a
admin_excluded    = Permission.where(resource: "roles", action: "destroy")
                              .or(Permission.where(resource: "site_settings"))
admin_permissions = all_permissions - admin_excluded.to_a

client_permissions = Permission.where(resource: %w[books authors], action: %w[index show])

[ superadmin_role, admin_role, client_role ].each(&:role_permissions).map(&:destroy_all) rescue nil

all_permissions.each do |perm|
  RolePermission.find_or_create_by!(role: superadmin_role, permission: perm)
end

admin_permissions.each do |perm|
  RolePermission.find_or_create_by!(role: admin_role, permission: perm)
end

client_permissions.each do |perm|
  RolePermission.find_or_create_by!(role: client_role, permission: perm)
end

puts "RolePermissions seeded"

# ===========================================================================
# SuperAdmin user — password must be at least 12 chars
# ===========================================================================
superadmin = User.find_or_initialize_by(email: "admin@clinicdev.com")
superadmin.otp_secret ||= ROTP::Base32.random
superadmin.assign_attributes(
  password: "Password1!Pw",
  verified: true,
  approved: true,
  role: superadmin_role
)
superadmin.save!

puts "SuperAdmin user: #{superadmin.email}"
