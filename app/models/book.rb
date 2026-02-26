class Book < ApplicationRecord
  include Discard::Model

  belongs_to :author, optional: true

  STATUSES = %w[active inactive draft].freeze

  validates :title, presence: true
  validates :status, inclusion: { in: STATUSES }, allow_nil: true
end
