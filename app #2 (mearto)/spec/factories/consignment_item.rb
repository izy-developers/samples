FactoryBot.define do
  factory :consignment_item do
    date_consigned { "2020-01-17" }
    min_estimate { 300 }
    max_estimate { 400 }
    proposed_auction_date { "2020-01-25" }
    currency { 0 }
  end
end
