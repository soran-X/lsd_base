class Role < ApplicationRecord
  HIERARCHY = {
    "SuperAdmin" => 100,
    "Admin"      => 50,
    "Client"     => 10
  }.freeze

  has_many :users, dependent: :nullify
  has_many :role_permissions, dependent: :destroy
  has_many :permissions, through: :role_permissions

  validates :name, presence: true, uniqueness: true
  validates :hierarchy_level, presence: true,
            numericality: { only_integer: true, greater_than: 0 }

  scope :ordered, -> { order(hierarchy_level: :desc) }

  # Returns roles that actor_role can assign (equal or below their level)
  def self.assignable_by(actor_role)
    return none if actor_role.nil?
    where("hierarchy_level <= ?", actor_role.hierarchy_level)
  end

  def superadmin? = hierarchy_level >= 100
  def admin?      = hierarchy_level >= 50
  def client?     = hierarchy_level >= 10

  # `create` is covered by the `new` permission; `update` by `edit`.
  ACTION_ALIASES = { "create" => "new", "update" => "edit" }.freeze

  def can?(action, resource)
    normalized = ACTION_ALIASES.fetch(action.to_s, action.to_s)
    permissions.exists?(action: normalized, resource: resource.to_s)
  end
end
