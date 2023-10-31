# frozen_string_literal: true

FactoryBot.define do
  factory :item do
    title { FFaker::Lorem.word }
    description { FFaker::Lorem.paragraph }
    provenance { FFaker::Lorem.word }
    is_for_sale { 1 }
    response_time { 48 }
    category
    seller
    channel
    marketplace_terms_of_service { false }

    trait :stripe do
      seller_id {}
      acquired_from { FFaker::Lorem.word }

      private { false }

      channel_id { Channel.last.id }
    end

    trait :create do
      is_for_sale { 'Yes' }
      response_time { 24 }
      channel_id { Channel.last.id }
    end
  end
end
