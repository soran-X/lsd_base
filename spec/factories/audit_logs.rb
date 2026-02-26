FactoryBot.define do
  factory :audit_log do
    association :user
    action        { "create" }
    resource_type { "Book" }
    resource_id   { 1 }
    metadata      { {} }
    ip_address    { "127.0.0.1" }
  end
end
