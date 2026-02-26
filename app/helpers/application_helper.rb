module ApplicationHelper
  def app_name
    SiteSetting.app_name
  end

  def theme_color(key, default)
    SiteSetting[key].presence || default
  end

  def logo_url
    if SiteSetting.logo_attached?
      blob = SiteSetting.logo_record.logo.blob
      rails_service_blob_proxy_path(signed_id: blob.signed_id, filename: blob.filename.to_s)
    else
      "/logo-white-horizontal.svg"
    end
  end

  def favicon_url
    if SiteSetting.favicon_attached?
      blob = SiteSetting.favicon_record.logo.blob
      rails_service_blob_proxy_path(signed_id: blob.signed_id, filename: blob.filename.to_s)
    else
      "/icon.svg"
    end
  end

  def pending_users_count
    User.where(approved: false).count
  end

  def admin_unread_conversations_count
    return 0 unless Current.user&.admin?
    Conversation.admin_unread_count
  end

  def client_unread_count
    return 0 unless Current.user&.approved? && Current.user.hierarchy_level < 50
    conv = Conversation.find_by(user: Current.user)
    conv ? conv.unread_for_client.count : 0
  end

  # Returns true if the hex color is perceptually dark (luminance < 0.5).
  def color_is_dark?(hex)
    hex = hex.gsub("#", "")
    r, g, b = hex.scan(/../).map { |c| c.to_i(16) }
    (0.299 * r + 0.587 * g + 0.114 * b) / 255.0 < 0.5
  end
end
