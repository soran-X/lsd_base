FactoryBot.define do
  factory :message do
    association :conversation
    association :user, :client
    body { Faker::Lorem.sentence }
    read_at { nil }

    trait :read do
      read_at { 1.hour.ago }
    end
  end
end
