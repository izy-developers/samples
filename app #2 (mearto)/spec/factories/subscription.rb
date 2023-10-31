# frozen_string_literal: true

FactoryBot.define do
  factory :subscription do
    subscribed_at { Time.now }
    association :seller_id, factory: [:user, :seller]
    active { true }

    trait :active do
      subscription_expires_at { 10.days.from_now }
    end

    trait :unactive do
      subscription_expires_at { 10.days.from_now }
    end
  end
end
