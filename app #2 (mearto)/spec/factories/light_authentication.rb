FactoryBot.define do
  factory :light_authentication do
    description { FFaker::Lorem.paragraph }
    genuine { 'genuine' }
  end
end
