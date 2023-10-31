FactoryBot.define do
  factory :comment do
    comment { 'Hello' }
    commentable_type { 'Appraisal' }
    role { 'comments' }
  end
end
