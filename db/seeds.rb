# ===========================================================================
# Roles
# ===========================================================================
superadmin_role = Role.find_or_create_by!(name: "SuperAdmin") { |r| r.hierarchy_level = 100 }
admin_role      = Role.find_or_create_by!(name: "Admin")      { |r| r.hierarchy_level = 50 }
scout_role      = Role.find_or_create_by!(name: "Scout")      { |r| r.hierarchy_level = 25 }
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
# Default sets — idempotent (adds missing, leaves custom additions alone).
# To fully reset a role, manually destroy its role_permissions first.
# ===========================================================================
all_permissions = Permission.all.to_a

# SuperAdmin — everything
superadmin_permissions = all_permissions

maintenance_resources = %w[company_types territories genres subgenres film_genres client_types]

# Admin — everything except site_settings
admin_permissions = all_permissions.reject { |p| p.resource == "site_settings" }

# Scout — content + book_searches + maintenance; NO users / roles / site_settings
scout_resources   = %w[books reports authors companies contacts book_searches] + maintenance_resources
scout_permissions = all_permissions.select { |p| scout_resources.include?(p.resource) }

# Client — read-only on books and reports only; NO authors/companies/contacts by default
client_resources   = %w[books reports]
client_permissions = all_permissions.select do |p|
  client_resources.include?(p.resource) && %w[index show].include?(p.action)
end

# Reset permissions for the 4 default roles so removals take effect too.
# Custom roles are untouched.
[
  [ superadmin_role, superadmin_permissions ],
  [ admin_role,      admin_permissions      ],
  [ scout_role,      scout_permissions      ],
  [ client_role,     client_permissions     ]
].each do |role, permissions|
  role.role_permissions.destroy_all
  permissions.each { |p| RolePermission.create!(role: role, permission: p) }
end

puts "RolePermissions seeded: SuperAdmin=#{superadmin_role.permissions.count}, Admin=#{admin_role.permissions.count}, Scout=#{scout_role.permissions.count}, Client=#{client_role.permissions.count}"

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

# ===========================================================================
# Territories
# ===========================================================================
%w[
  ANZ AUS BRA CAN CHN DNK ESP FIN FRA GER
  GRC HUN ITA JAP KOR NLD NOR POL POR RUS
  SWE TUR UK USA WOR
].each do |name|
  Territory.find_or_create_by!(name: name)
end

puts "Territories seeded: #{Territory.pluck(:name).join(', ')}"
