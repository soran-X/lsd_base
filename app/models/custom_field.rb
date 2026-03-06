class CustomField < ApplicationRecord
  enum :field_type, {
    text:                  0,
    rich_text:             1,
    checkbox:              2,
    combobox:              3,
    multi_combobox:        4,
    contact_select:        5,
    multi_contact_select:  6,
    company_select:        7,
    multi_company_select:  8
  }

  has_many :custom_field_values, dependent: :destroy

  validates :name,       presence: true
  validates :group_name, presence: true
  validates :field_type, presence: true

  scope :active,  -> { where(active: true) }
  scope :ordered, -> { order(:group_name, :position, :id) }

  def choices_for_select
    Array(choices).map(&:to_s).reject(&:blank?)
  end

  def multi?
    multi_combobox? || multi_contact_select? || multi_company_select?
  end

  def contact_type?
    contact_select? || multi_contact_select?
  end

  def company_type?
    company_select? || multi_company_select?
  end
end
