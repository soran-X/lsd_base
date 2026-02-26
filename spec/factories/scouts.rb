FactoryBot.define do
  factory :scout do
    sequence(:name) { |n| "Scout #{n}" }
    specialty { Faker::Job.field }
    notes { Faker::Lorem.sentence }
    active { true }
  end
end
