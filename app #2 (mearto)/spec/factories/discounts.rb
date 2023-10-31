FactoryBot.define do
  factory :discount do
    code { SecureRandom.hex(10) }
    kind { %w[referral custom].sample }
    value { %w[20 50].sample }
    description { 'Some test description' }
  end
end
