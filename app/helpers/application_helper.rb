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

  # fields whose rich-text contents we don't display; any attribute ending in
  # `_html`/`_plain` probably qualifies when coming from a Trix editor.
  AUDIT_RICH_TEXT_FIELDS = %w[synopsis notes readers_report].freeze

  # these boolean columns should render "Yes/No" instead of raw true/false;
  # we automatically include every boolean in the Book model so that newly
  # added flags are handled without editing this file.
  def audit_boolean_fields
    @audit_boolean_fields ||= begin
      base = Book.columns.select { |c| c.type == :boolean }.map(&:name)
      # keep a stable array for formatting; remove `discarded` since it's used
      # by paranoia and not something the user cares about seeing in the log
      base - %w[discarded]
    end
  end

  # when the model definition changes, we also want to skip typical metadata
  # attributes automatically rather than editing a constant each time.
  def audit_skip_fields
    @audit_skip_fields ||= begin
      # always ignore housekeeping columns and foreign keys (except the
      # last_updated_by we show separately via its name)
      Book.column_names.select { |n|
        n =~ /_at$/ ||
        n =~ /_id$/ && n != "last_updated_by_id"
      } + %w[synopsis_plain]
    end
  end

  # plain text values that should just be shown as-is instead of humanizing.
  AUDIT_PLAIN_FIELDS     = %w[authors translators].freeze

  def audit_skip_field?(field)
    audit_skip_fields.include?(field)
  end

  # Map field names to the model class and display method for ID resolution.
  AUDIT_ID_RESOLVERS = {
    "last_updated_by_id" => ->(id) { User.find_by(id: id)&.display_name },
    "primary_scout_id"   => ->(id) { User.find_by(id: id)&.display_name },
    "secondary_scout_id" => ->(id) { User.find_by(id: id)&.display_name },
    "contact_id"         => ->(id) { Contact.find_by(id: id)&.display_name },
    "company_id"         => ->(id) { Company.find_by(id: id)&.name },
  }.freeze

  def format_audit_value(field, value)
    return "—" if value.nil? || value.to_s.empty?
    return "[content updated]" if AUDIT_RICH_TEXT_FIELDS.include?(field) || field.end_with?("_html", "_plain")
    return(value ? "Yes" : "No") if audit_boolean_fields.include?(field)
    return value.to_s if AUDIT_PLAIN_FIELDS.include?(field)
    if (resolver = AUDIT_ID_RESOLVERS[field])
      return resolver.call(value.to_i)&.truncate(80) || value.to_s
    end
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
