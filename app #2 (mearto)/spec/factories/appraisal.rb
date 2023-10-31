FactoryBot.define do
  factory :appraisal do
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

    trait :auction_house do
      estimate_min_cents { 0 }
      estimate_max_cents { 0 }
      description { FFaker::Lorem.paragraph }
    end
  end
end
