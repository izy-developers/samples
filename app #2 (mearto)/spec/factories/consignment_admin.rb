FactoryBot.define do
  factory :consignment_admin do
    email { FFaker::Internet.unique.email }
    first_name { FFaker::Name.first_name }
    last_name { FFaker::Name.last_name }
    password { FFaker::Internet.password }
    channel
    country_id { 'AD' }
    type { 'ConsignmentAdmin' }
    department_id { FactoryBot.create(:department, :auction_house).id }
  end
end