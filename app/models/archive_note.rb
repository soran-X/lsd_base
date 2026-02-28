class ArchiveNote < ApplicationRecord
  include BookNestedAudit

  belongs_to :book
end
