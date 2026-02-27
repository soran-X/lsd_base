class BookSubGenre < ApplicationRecord
  belongs_to :book
  belongs_to :sub_genre
end
