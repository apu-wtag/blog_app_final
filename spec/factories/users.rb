FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    sequence(:user_name) { |n| "#{Faker::Internet.username(specifier: 5..10, separators: %w[_])}#{n}" }
    sequence(:email) { |n| "person#{n}@example.com" }
    password { "*Arnab1117#" }
    bio { Faker::Lorem.sentence }
    trait :discarded do
      discarded_at { Time.current }
    end
    trait :admin do
      role { :admin }
    end
    trait :editor do
      role { :editor }
    end
  end
end
