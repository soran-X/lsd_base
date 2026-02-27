class Author < ApplicationRecord
  include Discard::Model
  include PgSearch::Model

  # ── Associations ──────────────────────────────────────────────────────────
  has_many :book_authors, dependent: :destroy
  has_many :books, through: :book_authors

  # Convenience scopes for role-specific book lists
  has_many :authored_book_authors,    -> { author },     class_name: "BookAuthor"
  has_many :translated_book_authors,  -> { translator },  class_name: "BookAuthor"
  has_many :authored_books,   through: :authored_book_authors,   source: :book
  has_many :translated_books, through: :translated_book_authors, source: :book

  # ── Search ────────────────────────────────────────────────────────────────
  # Trigram search on the "Last, First" display format.
  # Handles accented names, partial matches, and slight typos.
  pg_search_scope :search_by_name,
    against: { last_name: "A", first_name: "B" },
    using: {
      trigram: {
        threshold:        0.1,
        word_similarity:  true
      }
    },
    ranked_by: ":trigram"

  # ── Validations ───────────────────────────────────────────────────────────
  validates :last_name, presence: true

  # ── Display helpers ───────────────────────────────────────────────────────
  # Canonical display format throughout the app: "García, Gabriel"
  def display_name
    first_name.present? ? "#{last_name}, #{first_name}" : last_name
  end

  def full_name
    [first_name, last_name].compact_blank.join(" ")
  end

  def to_s
    display_name
  end
end
