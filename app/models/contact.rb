class Contact < ApplicationRecord
  include Discard::Model
  include PgSearch::Model

  # ── Search ────────────────────────────────────────────────────────────────
  pg_search_scope :search_by_name,
    against: { last_name: "A", first_name: "A", email: "B" },
    using: { tsearch: { prefix: true, dictionary: "simple" },
             trigram: { word_similarity: true } }

  # ── Associations ──────────────────────────────────────────────────────────
  belongs_to :tracked_by, class_name: "User", optional: true
  has_many :contact_companies, dependent: :destroy
  has_many :companies, through: :contact_companies
  has_many :book_contacts, dependent: :destroy
  has_many :books, through: :book_contacts

  # ── Validations ───────────────────────────────────────────────────────────
  validates :first_name, :last_name, presence: true

  # ── Scopes ────────────────────────────────────────────────────────────────
  scope :ordered, -> { order(:last_name, :first_name) }

  def display_name = "#{last_name}, #{first_name}"
  def full_name    = "#{first_name} #{last_name}"
  def to_s         = display_name
end
