class ContactCompany < ApplicationRecord
  belongs_to :contact
  belongs_to :company

  validates :company_id, uniqueness: { scope: :contact_id }
end
