class BookContact < ApplicationRecord
  # ── Enums ─────────────────────────────────────────────────────────────────
  enum :role, {
    editor:         0,
    agent:          1,
    film_agent:     2,
    author_contact: 3,
    other:          4
  }, validate: true

  # ── Associations ──────────────────────────────────────────────────────────
  belongs_to :book
  belongs_to :contact

  # ── Validations ───────────────────────────────────────────────────────────
  validates :role, presence: true
  validates :contact_id, uniqueness: { scope: [:book_id, :role] }
end
 