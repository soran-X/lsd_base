class SiteSetting < ApplicationRecord
  has_one_attached :logo

  DEFAULTS = {
    "allow_public_signup"    => "false",
    "app_name"               => "ClinicDev",
    "primary_color"          => "#4f46e5",
    "secondary_color"        => "#111827",
    "tertiary_color"         => "#6366f1",
    "app_logo"               => "0",
    "favicon_icon"           => "0",
    "company_name"           => "",
    "company_tagline"        => "",
    "company_email"          => "",
    "company_phone"          => "",
    "company_website"        => "",
    "company_address"        => "",
    "company_contact_person" => "",
    "book_list_view"         => "table",
    "book_history_visibility" => "staff"
  }.freeze

  COMPANY_KEYS = %w[
    company_name company_tagline company_email
    company_phone company_website company_address company_contact_person
  ].freeze

  validates :key, presence: true, uniqueness: true

  def self.[](key)
    find_by(key: key)&.value
  end

  def self.enabled?(key)
    self[key.to_s].to_s.downcase == "true"
  end

  def self.allow_public_signup?
    enabled?("allow_public_signup")
  end

  def self.app_name
    self["app_name"].presence || "ClinicDev"
  end

  def self.logo_record
    find_by(key: "app_logo")
  end

  def self.logo_attached?
    logo_record&.logo&.attached? || false
  end

  def self.favicon_record
    find_by(key: "favicon_icon")
  end

  def self.favicon_attached?
    favicon_record&.logo&.attached? || false
  end

  # Returns all company details as a hash with symbol keys.
  # Usage: SiteSetting.company[:name], SiteSetting.company[:phone]
  def self.company
    COMPANY_KEYS.each_with_object({}) do |key, hash|
      short_key = key.sub("company_", "").to_sym
      hash[short_key] = self[key].presence
    end
  end

  # Returns a single company detail by key name (without the company_ prefix).
  # Usage: SiteSetting.company_detail(:name), SiteSetting.company_detail(:email)
  def self.company_detail(key)
    self["company_#{key}"].presence
  end

  def reset_to_default!
    default = DEFAULTS[key]
    return false unless DEFAULTS.key?(key)

    logo.purge if key.in?(%w[app_logo favicon_icon]) && logo.attached?
    update!(value: default.to_s)
    true
  end
end
