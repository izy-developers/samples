FactoryBot.define do
  factory :consign_invitation do
    trait :test do
      email { nil }
      department_id { nil }
    end
  end
end