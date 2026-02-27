class SubGenre < ApplicationRecord
  has_many :book_sub_genres, dependent: :destroy
  has_many :books,           through: :book_sub_genres

  validates :name, presence: true, uniqueness: true

  scope :ordered, -> { order(:name) }
end
