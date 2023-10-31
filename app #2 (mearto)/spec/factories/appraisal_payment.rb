FactoryBot.define do
  factory :appraisal_payment do
    paypal_id { SecureRandom.hex(10) }

    trait :paypal do
      seller_id {  }
      item_id {  }
    end
  end
end