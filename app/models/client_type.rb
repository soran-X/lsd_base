class ClientType < ApplicationRecord
  has_many :book_client_types, dependent: :destroy
  has_many :books, through: :book_client_types
  has_many :user_client_types, dependent: :destroy
  has_many :users, through: :user_client_types
  has_many :report_client_types, dependent: :destroy
  has_many :reports, through: :report_client_types

  validates :name, presence: true, uniqueness: true

  scope :ordered, -> { order(:name) }
end
