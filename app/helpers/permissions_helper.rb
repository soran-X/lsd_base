module PermissionsHelper
  def can?(action, resource)
    Current.user&.can?(action, resource) || false
  end

  def min_hierarchy?(level)
    Current.user&.hierarchy_level.to_i >= level
  end
end
