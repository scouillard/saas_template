FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { "password123" }

    trait :with_account do
      after(:create) do |user|
        create(:membership, user: user, role: :owner)
      end
    end

    trait :oauth do
      provider { "google_oauth2" }
      uid { Faker::Number.number(digits: 21).to_s }
    end
  end
end
