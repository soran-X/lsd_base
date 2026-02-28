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

  # Sanitize Trix-generated HTML — allows inline color styles on spans.
  TRIX_ALLOWED_TAGS  = (Rails::Html::SafeListSanitizer.allowed_tags  | %w[span s del pre code]).freeze
  TRIX_ALLOWED_ATTRS = (Rails::Html::SafeListSanitizer.allowed_attributes | %w[style]).freeze

  def trix_sanitize(html)
    return "" if html.blank?
    sanitize(html, tags: TRIX_ALLOWED_TAGS, attributes: TRIX_ALLOWED_ATTRS)
  end

  AUDIT_RICH_TEXT_FIELDS = %w[synopsis notes readers_report].freeze
  AUDIT_BOOLEAN_FIELDS   = %w[confidential lead_title tracking_material].freeze
  AUDIT_SKIP_FIELDS      = %w[updated_at synopsis_plain last_updated_by_id created_at discarded_at].freeze
  AUDIT_PLAIN_FIELDS     = %w[authors translators].freeze

  def audit_skip_field?(field)
    AUDIT_SKIP_FIELDS.include?(field)
  end

  def format_audit_value(field, value)
    return "—" if value.nil?
    return "[content updated]" if AUDIT_RICH_TEXT_FIELDS.include?(field)
    return(value ? "Yes" : "No") if AUDIT_BOOLEAN_FIELDS.include?(field)
    return value.to_s                if AUDIT_PLAIN_FIELDS.include?(field)
    value.to_s.humanize.truncate(80)
  end

  def audit_action_badge(action)
    css = case action
          when "create"  then "bg-green-100 text-green-700"
          when "update"  then "bg-blue-100 text-blue-700"
          when "discard" then "bg-red-100 text-red-600"
          else                "bg-gray-100 text-gray-600"
          end
    content_tag(:span, action.humanize,
                class: "inline-flex px-2 py-0.5 rounded-full text-xs font-medium #{css}")
  end

  # Returns true if the hex color is perceptually dark (luminance < 0.5).
  def color_is_dark?(hex)
    hex = hex.gsub("#", "")
    r, g, b = hex.scan(/../).map { |c| c.to_i(16) }
    (0.299 * r + 0.587 * g + 0.114 * b) / 255.0 < 0.5
  end
end
