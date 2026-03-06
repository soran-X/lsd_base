class Permission < ApplicationRecord
  # `new` covers new+create, `edit` covers edit+update.
  ALL_PERMISSIONS = {
    # Content
    "books"         => %w[index show new edit destroy],
    "reports"       => %w[index show new edit destroy],
    "authors"       => %w[index show new edit destroy],
    "companies"     => %w[index show new edit destroy],
    "contacts"      => %w[index show new edit destroy],
    "book_searches" => %w[index show new destroy],
    # Maintenance
    "users"         => %w[index show new edit destroy],
    "roles"         => %w[index show new edit destroy],
    "site_settings" => %w[index show edit],
    "company_types" => %w[index new edit destroy],
    "territories"   => %w[index new edit destroy],
    "genres"        => %w[index new edit destroy],
    "subgenres"     => %w[index new edit destroy],
    "film_genres"   => %w[index new edit destroy],
    "client_types"  => %w[index new edit destroy],
    "custom_fields" => %w[index new edit destroy]
  }.freeze

  has_many :role_permissions, dependent: :destroy
  has_many :roles, through: :role_permissions

  validates :resource, presence: true
  validates :action, presence: true
  validates :resource, uniqueness: { scope: :action }

  # Ensure every resource+action pair in ALL_PERMISSIONS exists as a DB row.
  def self.sync_all!
    ALL_PERMISSIONS.each do |resource, actions|
      actions.each { |action| find_or_create_by!(resource: resource, action: action) }
    end
  end
end
