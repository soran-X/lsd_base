class CustomReportTemplate < ApplicationRecord
  # Delegate to InstanceConfig — the single source of truth for field availability.
  # Use these class methods everywhere instead of the old constants.
  def self.available_fields = InstanceConfig.available_report_fields
  def self.field_groups     = InstanceConfig.field_groups

  belongs_to :created_by, class_name: "User", optional: true
  has_many :template_fields, -> { order(:position) }, class_name: "CustomReportTemplateField", dependent: :destroy
  has_many :sections, -> { order(:position) }, class_name: "CustomReportTemplateSection", dependent: :destroy
  has_many :reports, dependent: :nullify

  accepts_nested_attributes_for :sections, allow_destroy: true, reject_if: :all_blank

  validates :name, presence: true, uniqueness: true

  def field_keys
    template_fields.pluck(:field_key)
  end

  def rebuild_fields!(keys)
    template_fields.destroy_all
    Array(keys).each_with_index do |key, i|
      template_fields.create!(field_key: key, position: i)
    end
  end
end
