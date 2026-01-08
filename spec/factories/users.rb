FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password { "Password123" }
    password_confirmation { "Password123" }

    trait :with_sessions do
      after(:create) do |user|
        create_list(:session, 2, user: user)
      end
    end
  end
end
