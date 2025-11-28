FactoryBot.define do
  factory :membership do
    user { nil }
    account { nil }
    role { "MyString" }
  end
end
