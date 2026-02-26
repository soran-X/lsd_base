FactoryBot.define do
  factory :site_setting do
    sequence(:key) { |n| "setting_key_#{n}" }
    value { "true" }

    trait :signup_enabled do
      key   { "allow_public_signup" }
      value { "true" }
    end

    trait :signup_disabled do
      key   { "allow_public_signup" }
      value { "false" }
    end
  end
end
