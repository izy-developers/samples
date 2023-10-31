FactoryBot.define do
  factory :auction_house_user do
    email { FFaker::Internet.unique.email }
    name { FFaker::Name.first_name }
    phone { FFaker::PhoneNumber }
    organisation { FactoryBot.create(:organisation) }
  end
end
