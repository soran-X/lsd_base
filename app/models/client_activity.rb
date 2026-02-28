class ClientActivity < ApplicationRecord
  belongs_to :book
  belongs_to :company, optional: true
  belongs_to :contact, optional: true
end
