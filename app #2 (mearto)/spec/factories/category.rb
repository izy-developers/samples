FactoryBot.define do
  factory :category do
    name { 'First Category' }
    description { 'laids falsid falsdif' }
    show_in_form { true }

    trait :second do
      name { 'Second Category' }
    end

    trait :sell_art do
      id { '7e8f7e19-4016-4111-9dd8-2cd48ce5251d' }
    end
  end
end
