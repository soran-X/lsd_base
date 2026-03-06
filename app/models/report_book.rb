class ReportBook < ApplicationRecord
  belongs_to :report
  belongs_to :book
end
