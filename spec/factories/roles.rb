FactoryBot.define do
  factory :role do
    sequence(:name) { |n| "Role #{n}" }
    hierarchy_level { 10 }

    trait :superadmin do
      name { "SuperAdmin" }
      hierarchy_level { 100 }
    end

    trait :admin do
      name { "Admin" }
      hierarchy_level { 50 }
    end

    trait :client do
      name { "Client" }
      hierarchy_level { 10 }
    end
  end
end
