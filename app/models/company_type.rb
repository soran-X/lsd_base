class CompanyType < ApplicationRecord
  has_many :companies

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :ordered, -> { order(:name) }

  def to_s = name
end
