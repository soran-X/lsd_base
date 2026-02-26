class Scout < ApplicationRecord
  include Discard::Model

  validates :name, presence: true
  validates :active, inclusion: { in: [ true, false ] }, allow_nil: true
end
