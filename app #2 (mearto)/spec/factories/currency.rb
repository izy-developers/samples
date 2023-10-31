FactoryBot.define do
  factory :currency do
    name { 'USD' }
    rate_to_eur { 1.3 }
  end
end
