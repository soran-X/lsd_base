class Book < ApplicationRecord
  include Discard::Model
  include PgSearch::Model

  # ── Search ────────────────────────────────────────────────────────────────
  pg_search_scope :search_globally,
    against: { title: "A", old_title: "B", synopsis_plain: "C" },
    associated_against: { authors: { last_name: "A", first_name: "A" } },
    using: {
      tsearch: { prefix: true, dictionary: "simple" }
    }

  # ── Enums ─────────────────────────────────────────────────────────────────
  enum :status, {
    draft:    0,
    active:   1,
    inactive: 2,
    acquired: 3,
    passed:   4
  }, validate: true

  # ── Associations ──────────────────────────────────────────────────────────
  belongs_to :primary_scout,    class_name: "User", optional: true
  belongs_to :secondary_scout,  class_name: "User", optional: true
  belongs_to :last_updated_by,  class_name: "User", optional: true

  has_many :book_authors,  dependent: :destroy
  has_many :authors,       through: :book_authors

  # Role-scoped author shortcuts
  has_many :book_author_roles,       -> { author },     class_name: "BookAuthor"
  has_many :book_translator_roles,   -> { translator },  class_name: "BookAuthor"
  has_many :credited_authors,      through: :book_author_roles,      source: :author
  has_many :translators,           through: :book_translator_roles,   source: :author

  has_one  :film_tracking, dependent: :destroy

  has_many :book_genres,      dependent: :destroy
  has_many :genres,           through: :book_genres

  has_many :book_sub_genres,  dependent: :destroy
  has_many :sub_genres,       through: :book_sub_genres

  has_many :book_client_types, dependent: :destroy
  has_many :client_types,      through: :book_client_types

  has_many :book_companies, dependent: :destroy
  has_many :companies,      through: :book_companies

  # Role-scoped company shortcuts
  has_one  :book_publisher_record,   -> { publisher },   class_name: "BookCompany"
  has_one  :publisher_company,       through: :book_publisher_record, source: :company
  has_one  :book_editor_record,      -> { editor },      class_name: "BookCompany"
  has_one  :editor_company,          through: :book_editor_record,   source: :company
  has_many :book_agency_records,     -> { agency },      class_name: "BookCompany"
  has_many :agency_companies,        through: :book_agency_records,  source: :company
  has_many :book_film_agency_records, -> { film_agency }, class_name: "BookCompany"
  has_many :film_agency_companies,   through: :book_film_agency_records, source: :company

  has_many :book_contacts, dependent: :destroy
  has_many :contacts,      through: :book_contacts

  # Role-scoped contact shortcuts
  has_many :book_agent_records,       -> { agent },       class_name: "BookContact"
  has_many :agent_contacts,           through: :book_agent_records,      source: :contact
  has_many :book_film_agent_records,  -> { film_agent },  class_name: "BookContact"
  has_many :film_agent_contacts,      through: :book_film_agent_records, source: :contact

  has_many :reading_materials, dependent: :destroy
  has_many :client_activities, dependent: :destroy
  has_many :book_memos,        dependent: :destroy
  has_many :archive_notes,     dependent: :destroy

  # ── Nested attributes ─────────────────────────────────────────────────────
  accepts_nested_attributes_for :film_tracking,     allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :reading_materials, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :client_activities, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :book_memos,        allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :archive_notes,     allow_destroy: true, reject_if: :all_blank

  # ── Constants ─────────────────────────────────────────────────────────────
  SEASONS = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December",
    "Winter", "Spring", "Summer", "Fall", "TBA"
  ].freeze

  PUBLICATION_YEARS = ((1950..Time.current.year).to_a.reverse).freeze

  # ── Validations ───────────────────────────────────────────────────────────
  validates :title, presence: true

  # ── Callbacks ─────────────────────────────────────────────────────────────
  before_save :extract_synopsis_plain

  # ── Helpers ───────────────────────────────────────────────────────────────
  def display_authors
    credited_authors.map(&:display_name).join(", ")
  end

  def display_translators
    translators.map(&:display_name).join(", ")
  end

  private

  def extract_synopsis_plain
    return unless synopsis_changed? || (synopsis.present? && synopsis_plain.nil?)
    self.synopsis_plain = synopsis.present? ?
      synopsis
        .gsub(/<[^>]+>/, " ")
        .gsub(/&[a-zA-Z]+;|&#\d+;/, " ")
        .gsub(/\s+/, " ")
        .strip :
      nil
  end
end
