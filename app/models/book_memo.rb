class BookMemo < ApplicationRecord
  include BookNestedAudit

  belongs_to :book
end
