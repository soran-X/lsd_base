class Company < ApplicationRecord
  # ── Associations ──────────────────────────────────────────────────────────
  has_many :book_companies, dependent: :destroy
  has_many :books, through: :book_companies

  # ── Validations ───────────────────────────────────────────────────────────
  validates :name, presence: true

  def to_s = name
end
