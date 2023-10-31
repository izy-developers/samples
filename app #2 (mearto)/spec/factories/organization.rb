FactoryBot.define do
  factory :organisation do
    name { 'Mearto' }
    url { 'http://www.mearto.com' }
    address {'copenhagen'}
    address2 {'hej'}
    country_id {'DK'}
    placement { 'Premium' }
    description { FFaker::Lorem.sentence }

    trait :auction_house do
      name { FFaker::Lorem.word }
      url { 'http://www.auction_house.com' }
    end
  end
end
