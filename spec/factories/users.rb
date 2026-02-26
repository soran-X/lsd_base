FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    first_name { Faker::Name.first_name }
    last_name  { Faker::Name.last_name }
    password { "Password1!Pw" }
    password_confirmation { "Password1!Pw" }
    verified { true }
    approved { false }
    otp_secret { ROTP::Base32.random }

    trait :approved do
      approved { true }
    end

    trait :unapproved do
      approved { false }
    end

    trait :superadmin do
      approved { true }
      after(:build) do |user|
        user.role = Role.find_or_create_by!(name: "SuperAdmin") { |r| r.hierarchy_level = 100 }
      end
    end

    trait :admin do
      approved { true }
      after(:build) do |user|
        user.role = Role.find_or_create_by!(name: "Admin") { |r| r.hierarchy_level = 50 }
      end
    end

    trait :client do
      approved { true }
      after(:build) do |user|
        user.role = Role.find_or_create_by!(name: "Client") { |r| r.hierarchy_level = 10 }
      end
    end

    trait :oauth_user do
      provider { "google_oauth2" }
      sequence(:uid) { |n| "google-uid-#{n}" }
      password { SecureRandom.base58(24) }
      password_confirmation { nil }
      verified { true }
    end
  end
end
