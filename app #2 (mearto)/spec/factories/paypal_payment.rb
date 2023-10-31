FactoryBot.define do
  factory :paypal_payment do
    paypal_id { SecureRandom.hex(10) }

    trait :paypal do
      item_id {  }
    end
  end
end