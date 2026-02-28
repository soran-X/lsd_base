class CompanySubagent < ApplicationRecord
  belongs_to :company
  belongs_to :subagent_company, class_name: "Company"
  belongs_to :territory, optional: true

  validates :subagent_company_id, presence: true
end
