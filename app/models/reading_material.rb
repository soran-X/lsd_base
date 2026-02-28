class ReadingMaterial < ApplicationRecord
  include BookNestedAudit

  belongs_to :book
end
