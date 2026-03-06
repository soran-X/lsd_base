class ReportClientType < ApplicationRecord
  belongs_to :report
  belongs_to :client_type
end
