FactoryBot.define do
  factory :ebay_category do
    name { FFaker::Lorem.word }
    ebay_category_id { FFaker::Random.rand max = 100 }
  end
end
