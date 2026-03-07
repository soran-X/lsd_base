class Report < ApplicationRecord
  include PgSearch::Model

  TYPES = {
    reading_list:     0,
    follow_up_list:   1,
    ya_highlights:    2,
    adult_highlights: 3,
    netflix_report:   4,
    film_memo:        5,
    custom:           6
  }.freeze

  TYPE_LABELS = {
    "reading_list"     => "Reading List",
    "follow_up_list"   => "Follow Up List",
    "ya_highlights"    => "YA Highlights",
    "adult_highlights" => "Adult Highlights",
    "netflix_report"   => "Netflix Report",
    "film_memo"        => "Film Memo"
  }.freeze

  enum :report_type, TYPES

  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :custom_report_template, optional: true
  has_many :report_client_types, dependent: :destroy
  has_many :client_types, through: :report_client_types
  has_many :report_books, -> { order(:position) }, dependent: :destroy
  has_many :books, through: :report_books

  validates :title, presence: true
  validates :report_type, presence: true

  pg_search_scope :search_by_title,
    against: :title,
    using: { tsearch: { prefix: true } }

  def type_label
    if custom?
      custom_report_template&.name || "Custom"
    else
      TYPE_LABELS[report_type] || report_type&.humanize
    end
  end

  def renderer
    case report_type
    when "film_memo"        then ReportRenderers::FilmMemoRenderer.new(self)
    when "adult_highlights" then ReportRenderers::AdultHighlightsRenderer.new(self)
    when "custom"           then ReportRenderers::CustomRenderer.new(self)
    else                         ReportRenderers::DefaultRenderer.new(self)
    end
  end

  def regenerate!
    update!(rendered_content: renderer.render)
  end
end
