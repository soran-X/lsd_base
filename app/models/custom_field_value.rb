class CustomFieldValue < ApplicationRecord
  belongs_to :book
  belongs_to :custom_field

  validates :book_id, uniqueness: { scope: :custom_field_id }

  # Returns a human-readable string for display in show views.
  # Resolves contact/company IDs to names where needed.
  def display_value
    return "" if value_json.blank?

    case custom_field.field_type.to_sym
    when :checkbox
      value_json == true || value_json == "1" || value_json == "true" ? "Yes" : "No"
    when :contact_select
      id = value_json.to_i
      Contact.find_by(id: id)&.display_name || value_json.to_s
    when :multi_contact_select
      ids = Array(value_json).map(&:to_i).reject(&:zero?)
      Contact.where(id: ids).map(&:display_name).join(", ")
    when :company_select
      id = value_json.to_i
      Company.find_by(id: id)&.name || value_json.to_s
    when :multi_company_select
      ids = Array(value_json).map(&:to_i).reject(&:zero?)
      Company.where(id: ids).map(&:name).join(", ")
    else
      value_json.to_s
    end
  end
end
