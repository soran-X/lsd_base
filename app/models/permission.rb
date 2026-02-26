class Permission < ApplicationRecord
  # `new` covers new+create, `edit` covers edit+update.
  ALL_PERMISSIONS = {
    "books"         => %w[index show new edit destroy],
    "authors"       => %w[index show new edit destroy],
    "scouts"        => %w[index show new edit destroy],
    "users"         => %w[index show edit destroy],
    "roles"         => %w[index show new edit destroy],
    "site_settings" => %w[index show edit]
  }.freeze

  has_many :role_permissions, dependent: :destroy
  has_many :roles, through: :role_permissions

  validates :resource, presence: true
  validates :action, presence: true
  validates :resource, uniqueness: { scope: :action }
end
