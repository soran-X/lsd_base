FactoryBot.define do
  factory :permission do
    sequence(:resource) { |n| "resource#{n}" }
    sequence(:action)   { |n| "action#{n}" }
  end
end
