FactoryBot.define do
  factory :task do
    name { "Test Task" }
    status { "pending" }
    project

    trait :completed do
      status { "completed" }
    end

    trait :in_progress do
      status { "in_progress" }
    end
  end
end
