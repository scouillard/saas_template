FactoryBot.define do
  factory :account_invitation do
    account
    inviter factory: :user
    email { Faker::Internet.email }
    expires_at { 7.days.from_now }
  end
end
