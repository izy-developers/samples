FactoryBot.define do
  factory :seller do
    first_name { FFaker::Name.first_name }
    last_name { FFaker::Name.last_name }
    email { FFaker::Internet.unique.email }
    address { FFaker::Address.street_address(true) }
    country_id { 'AD' }
    phone { Faker::PhoneNumber.cell_phone }
    time_zone { 'London' }
    password { FFaker::Internet.password }
    type { 'Seller' }
    channel

    trait :mearto_channel do
      channel { create(:channel) }
    end

    trait :other_channel do
      channel { create(:channel, name: :invaluable) }
    end

    trait :no_country do
      country_id {}
    end
  end
end
