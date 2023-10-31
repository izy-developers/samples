FactoryBot.define do
  factory :auction_house_appraisal do
    estimate_min_cents { 0 }
    estimate_max_cents { 0 }
    description { FFaker::Lorem.paragraph }
  end
end
