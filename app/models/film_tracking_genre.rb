class FilmTrackingGenre < ApplicationRecord
  belongs_to :film_tracking
  belongs_to :film_genre
  validates :film_genre_id, uniqueness: { scope: :film_tracking_id }
end
