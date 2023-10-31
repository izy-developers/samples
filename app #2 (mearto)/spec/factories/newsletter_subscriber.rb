FactoryBot.define do
  factory :newsletter_subscriber do
    email { Faker::Internet.email }

    factory :newsletter_subscriber_with_user do
      transient do
        user_count { 2 }
      end

      before(:create) do |newsletter_subscriber, evaluator|
        evaluator.user_count.times do
          newsletter_subscriber.user_id = create(:seller).id
        end
      end
    end
  end
end
