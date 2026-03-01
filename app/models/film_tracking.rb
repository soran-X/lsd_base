class FilmTracking < ApplicationRecord
  # ── Associations ──────────────────────────────────────────────────────────
  belongs_to :book

  has_many :film_tracking_genres, dependent: :destroy
  has_many :film_genres, through: :film_tracking_genres

  # ── Validations ───────────────────────────────────────────────────────────
  validates :book_id, uniqueness: true
end
