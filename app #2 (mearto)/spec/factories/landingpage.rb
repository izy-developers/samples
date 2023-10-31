FactoryBot.define do
  factory :landingpage do
    name { FFaker::Lorem.word }
    description { FFaker::Lorem.paragraph }
    faq { FFaker::Lorem.paragraph }
    slug { FFaker::Lorem.word }
  end
end