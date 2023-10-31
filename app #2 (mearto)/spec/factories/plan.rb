# frozen_string_literal: true

FactoryBot.define do
  factory :plan do
    currency { 'usd' }
    interval { 'monthly' }
    active { true }

    trait :basic do
      name { 'Basic' }
      slug { 'basic' }
      stripe_id { 'basic2' }
      price { 17 }
    end

    trait :premium do
      name { 'Premium' }
      slug { 'premium' }
      stripe_id { 'premium' }
      price { 22 }
    end
  end
end
