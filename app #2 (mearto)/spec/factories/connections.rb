FactoryBot.define do
  factory :connection do
    trait :test do
      seller { nil }
      specialist { nil }
    end
  end
end
