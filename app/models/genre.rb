class Genre < ApplicationRecord
  has_many :book_genres, dependent: :destroy
  has_many :books,       through: :book_genres

  validates :name, presence: true, uniqueness: true

  scope :ordered, -> { order(:name) }
end
