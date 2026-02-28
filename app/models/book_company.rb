class BookCompany < ApplicationRecord
  # ── Enums ─────────────────────────────────────────────────────────────────
  enum :role, {
    publisher:   0,
    agency:      1,
    film_agency: 2,
    distributor: 3,
    other:       4,
    editor:      5
  }, validate: true

  # ── Associations ──────────────────────────────────────────────────────────
  belongs_to :book
  belongs_to :company

  # ── Validations ───────────────────────────────────────────────────────────
  validates :role, presence: true
  validates :company_id, uniqueness: { scope: [:book_id, :role] }
end
