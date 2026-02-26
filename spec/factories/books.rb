FactoryBot.define do
  factory :book do
    sequence(:title) { |n| "Book Title #{n}" }
    description { Faker::Lorem.paragraph }
    published_at { Faker::Date.backward(days: 365) }
    status { "active" }
    association :author
  end
end
