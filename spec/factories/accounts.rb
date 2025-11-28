FactoryBot.define do
  factory :account do
    name { Faker::Company.name }
    plan { :free }
    subscription_status { :none }

    trait :with_stripe do
      stripe_customer_id { "cus_#{Faker::Alphanumeric.alphanumeric(number: 14)}" }
      stripe_subscription_id { "sub_#{Faker::Alphanumeric.alphanumeric(number: 14)}" }
      stripe_price_id { "price_#{Faker::Alphanumeric.alphanumeric(number: 14)}" }
      subscription_status { :active }
      subscription_started_at { 1.month.ago }
      subscription_ends_at { 11.months.from_now }
    end

    trait :pro do
      plan { :pro }
    end

    trait :business do
      plan { :business }
    end
  end
end
