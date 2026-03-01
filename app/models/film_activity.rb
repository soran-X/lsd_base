class FilmActivity < ApplicationRecord
  belongs_to :book
  belongs_to :company, optional: true
end
