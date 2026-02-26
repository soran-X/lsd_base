FactoryBot.define do
  factory :author do
    sequence(:name) { |n| "Author #{n}" }
    bio { Faker::Lorem.paragraph }
  end
end
