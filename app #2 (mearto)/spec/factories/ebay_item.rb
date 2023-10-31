FactoryBot.define do
  factory :ebay_item do
    description { FFaker::Lorem.words num = 3 }
    ebay_id { FFaker::Guid.guid }
    ebay_url { 'https://www.ebay.com/itm/Alec-Monopoly-oil-painting-canvas-Abstract-Graffiti-art-decor-Jack-N-28x28-/202021972916' }
  end
end
