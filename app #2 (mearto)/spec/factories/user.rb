FactoryBot.define do
  factory :user do
    email { FFaker::Internet.unique.email }
    first_name { FFaker::Name.unique.first_name }
    last_name { FFaker::Name.unique.last_name }
    password { FFaker::Internet.password }
    type { 'Guest' }

    trait :seller do
      channel
      country_id { 'AD' }
      type { 'Seller' }
    end

    trait :specialist do
      channel
      country_id { 'AD' }
      type { 'Specialist' }
      department_id { FactoryBot.create(:department).id }
    end

    trait :god do
      type { 'God' }
    end

    trait :billy_id do
      billy_id { FFaker::Lorem.word }
    end
  end
end