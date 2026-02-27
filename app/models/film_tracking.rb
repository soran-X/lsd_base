class FilmTracking < ApplicationRecord
  # ── Associations ──────────────────────────────────────────────────────────
  belongs_to :book

  # ── Validations ───────────────────────────────────────────────────────────
  validates :book_id, uniqueness: true
end
