FactoryBot.define do
  factory :god do
    email { FFaker::Internet.unique.email }
    first_name { FFaker::Name.first_name }
    last_name { FFaker::Name.last_name }
    password { FFaker::Internet.password }
    channel
    country_id { 'AD' }
    type { 'God' }
    department_id { FactoryBot.create(:department).id }
  end
end