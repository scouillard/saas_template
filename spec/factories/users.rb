FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { "password123" }
    confirmed_at { Time.current }

    trait :oauth do
      provider { "google_oauth2" }
      uid { Faker::Number.number(digits: 21).to_s }
    end

    trait :admin do
      admin { true }
    end
  end
end
