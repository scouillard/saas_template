FactoryBot.define do
  factory :account_invitation do
    account
    email { Faker::Internet.email }
    association :invited_by, factory: :user
    expires_at { 7.days.from_now }

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :accepted do
      accepted_at { 1.hour.ago }
    end
  end
end
