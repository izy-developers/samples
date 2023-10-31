FactoryBot.define do
  factory :invoice do
    subtotal_amount { 1000 }
    total_amount { 1000 }
    currency { 'usd' }

    trait :appraisal do
      type { 'AppraisalInvoice' }
      user_id {  }
      paypal_id {  }
    end
  end
end