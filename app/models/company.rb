class Company < ApplicationRecord
  include Discard::Model
  include PgSearch::Model

  # ── Search ────────────────────────────────────────────────────────────────
  pg_search_scope :search_by_name,
    against: { name: "A", city: "B", country: "C" },
    using: { tsearch: { prefix: true, dictionary: "simple" },
             trigram: { word_similarity: true } }

  # ── Associations ──────────────────────────────────────────────────────────
  belongs_to :company_type, optional: true
  has_many :book_companies, dependent: :destroy
  has_many :books, through: :book_companies
  has_many :contacts, dependent: :nullify
  has_many :company_subagents, dependent: :destroy
  has_many :subagent_companies, through: :company_subagents, source: :subagent_company

  accepts_nested_attributes_for :company_subagents,
    allow_destroy: true, reject_if: proc { |a| a[:subagent_company_id].blank? }

  # ── Validations ───────────────────────────────────────────────────────────
  validates :name, presence: true

  # ── Scopes ────────────────────────────────────────────────────────────────
  scope :ordered, -> { order(:name) }

  def to_s = name
end
