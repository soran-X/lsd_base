class BookClientType < ApplicationRecord
  belongs_to :book
  belongs_to :client_type
end
