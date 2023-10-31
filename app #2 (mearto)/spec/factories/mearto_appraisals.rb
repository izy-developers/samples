FactoryBot.define do
  factory :mearto_appraisal do
    estimate_min_cents { 100 }
    estimate_max_cents { 300 }
    currency { "US" }
    description { FFaker::Lorem.paragraph }
    user_is_interested { [true, false].sample }
    fake { [true, false].sample}
    conditional { [true, false].sample }
    type { 'MeartoAppraisal' }
    consign_initiated { [true, false].sample }
    auction_houses_recommendation { FFaker::Name.name }
    suggested_asking_price_cents { 300_00 }
  end
end
