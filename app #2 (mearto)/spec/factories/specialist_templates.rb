FactoryBot.define do
  factory :specialist_template do
    title { FFaker::Lorem.word.capitalize }
    text { FFaker::Lorem.paragraph }
    approved { false }
  end
end
