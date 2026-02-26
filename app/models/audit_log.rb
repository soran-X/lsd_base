class AuditLog < ApplicationRecord
  belongs_to :user, optional: true

  validates :action, presence: true
  validates :resource_type, presence: true

  def self.record(user:, action:, resource:, metadata: {}, request: nil)
    create!(
      user:          user,
      action:        action.to_s,
      resource_type: resource.class.name,
      resource_id:   resource.try(:id),
      metadata:      metadata,
      ip_address:    request&.ip
    )
  rescue ActiveRecord::RecordInvalid
    nil
  end
end
