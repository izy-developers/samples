FactoryBot.define do
  factory :department do
    name { 'general' }
    organisation

    trait :auction_house do
      name { FFaker::Lorem.word }
      organisation { FactoryBot.create(:organisation, :auction_house) }
    end
  end
end