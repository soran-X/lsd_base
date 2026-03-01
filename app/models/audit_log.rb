class AuditLog < ApplicationRecord
  belongs_to :user, optional: true

  validates :action, presence: true
  validates :resource_type, presence: true

  PER_RESOURCE_LIMIT = ENV.fetch("AUDIT_LOG_PER_RESOURCE_LIMIT", 1000).to_i

  def self.record(user:, action:, resource:, metadata: {}, request: nil)
    log = create!(
      user:          user,
      action:        action.to_s,
      resource_type: resource.class.name,
      resource_id:   resource.try(:id),
      metadata:      metadata,
      ip_address:    request&.ip
    )
    purge_old_for(resource)
    log
  rescue ActiveRecord::RecordInvalid
    nil
  end

  def self.purge_old_for(resource)
    resource_id   = resource.try(:id)
    resource_type = resource.class.name
    return unless resource_id

    cutoff = where(resource_type: resource_type, resource_id: resource_id)
               .order(created_at: :desc)
               .offset(PER_RESOURCE_LIMIT)
               .limit(1)
               .pluck(:created_at)
               .first
    return unless cutoff

    where(resource_type: resource_type, resource_id: resource_id)
      .where("created_at <= ?", cutoff)
      .delete_all
  end
end
