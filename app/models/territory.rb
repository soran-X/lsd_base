class Territory < ApplicationRecord
  has_many :company_subagents, dependent: :nullify

  validates :name, presence: true, uniqueness: true

  scope :ordered, -> { order(:name) }

  def to_s = name
end
