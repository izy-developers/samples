FactoryBot.define do
  factory :channel do
    name { 'mearto' }
    urgent_price { 100 }
    basic_price  { 1500 }
    private_price { 200 }
  end
end
