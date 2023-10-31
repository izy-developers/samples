FactoryBot.define do
  factory :message do
    body { FFaker::Lorem.paragraph }
  end
end