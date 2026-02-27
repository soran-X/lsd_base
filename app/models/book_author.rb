class BookAuthor < ApplicationRecord
  # ── Enums ─────────────────────────────────────────────────────────────────
  enum :role, { author: 0, translator: 1 }, validate: true

  # ── Associations ──────────────────────────────────────────────────────────
  belongs_to :book
  belongs_to :author

  # ── Validations ───────────────────────────────────────────────────────────
  validates :role, presence: true
  validates :author_id, uniqueness: {
    scope: [:book_id, :role],
    message: "already has this role on this book"
  }
end
