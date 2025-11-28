FactoryBot.define do
  factory :account do
    name { "MyString" }
    plan { "MyString" }
    stripe_customer_id { "MyString" }
    stripe_subscription_id { "MyString" }
    subscription_started_at { "2025-11-27 19:19:50" }
    subscription_ends_at { "2025-11-27 19:19:50" }
  end
end
