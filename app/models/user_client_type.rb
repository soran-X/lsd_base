class UserClientType < ApplicationRecord
  belongs_to :user
  belongs_to :client_type
end
