class AddCompanySiteSettings < ActiveRecord::Migration[8.1]
  COMPANY_KEYS = {
    "company_name"           => "",
    "company_tagline"        => "",
    "company_email"          => "",
    "company_phone"          => "",
    "company_website"        => "",
    "company_address"        => "",
    "company_contact_person" => ""
  }.freeze

  def up
    COMPANY_KEYS.each do |key, default|
      SiteSetting.find_or_create_by!(key: key) { |s| s.value = default }
    end
  end

  def down
    SiteSetting.where(key: COMPANY_KEYS.keys).destroy_all
  end
end
