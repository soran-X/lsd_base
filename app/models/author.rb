class Author < ApplicationRecord
  include Discard::Model

  has_many :books, dependent: :nullify

  validates :name, presence: true
end
