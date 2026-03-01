class FilmGenre < ApplicationRecord
  include PgSearch::Model

  pg_search_scope :search_by_name,
    against: :name,
    using: { trigram: { word_similarity: true } }

  has_many :film_tracking_genres, dependent: :destroy
  has_many :film_trackings, through: :film_tracking_genres

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :ordered, -> { order(:name) }
end
