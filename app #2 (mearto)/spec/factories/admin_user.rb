FactoryBot.define do
  factory :admin_user do
    email { FFaker::Internet.unique.email }
    password { FFaker::Internet.password }
  end
end
