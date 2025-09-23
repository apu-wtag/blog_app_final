FactoryBot.define do
  factory :moderation_record do
    article { nil }
    admin { nil }
    admin_reason { "MyText" }
    author_note { "MyText" }
    status { 1 }
  end
end
