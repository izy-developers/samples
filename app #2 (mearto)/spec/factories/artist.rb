FactoryBot.define do
  factory :artist do
    name { FFaker::Name.unique.first_name }
  end
end