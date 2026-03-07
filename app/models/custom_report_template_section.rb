class CustomReportTemplateSection < ApplicationRecord
  belongs_to :custom_report_template

  validates :name, presence: true
end
