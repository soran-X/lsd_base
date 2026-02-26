module Authorizable
  extend ActiveSupport::Concern

  included do
    helper_method :can?
  end

  def can?(action, resource)
    Current.user&.can?(action, resource) || false
  end

  def authorize!(action, resource)
    unless can?(action, resource)
      redirect_to dashboard_path, alert: "Access denied."
    end
  end

  def require_min_hierarchy!(level)
    unless Current.user&.hierarchy_level.to_i >= level
      redirect_to dashboard_path, alert: "Access denied."
    end
  end
end
