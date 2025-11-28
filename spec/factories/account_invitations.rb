FactoryBot.define do
  factory :account_invitation do
    account
    invited_by { association :user }
    email { Faker::Internet.email }
    expires_at { 7.days.from_now }

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :accepted do
      accepted_at { 1.day.ago }
    end
  end
end
