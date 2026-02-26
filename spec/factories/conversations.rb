FactoryBot.define do
  factory :conversation do
    association :user, :client
    status { "open" }
  end
end
