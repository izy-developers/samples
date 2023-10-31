require "rails_helper"

RSpec.describe Specialist, type: :model do
  context "Test validation" do
    it "should be valid" do
      expect(FactoryBot.build(:specialist)).to be_valid
    end
  end

  context "Test method" do
    let (:specialist) { FactoryBot.create(:specialist) }
    let (:seller) { FactoryBot.create(:user, :seller) }
    let (:item) { FactoryBot.create(:item, seller_id: seller.id) }
    let! (:appraisal) { FactoryBot.create(:mearto_appraisal, item_id: item.id, specialist_id: specialist.id) }
    let (:month) { Time.now.strftime("%B %y") }

    it "group_count_appraisal_by_month should be empty" do
      item.update(created_at: Time.now - (60*60*50))
      expect(specialist.group_count_appraisal_by_month[0][:data]).to eq([[month, 0]])
    end

    it "group_count_appraisal_by_month should be true" do
      FactoryBot.create(:item, seller_id: seller.id)
      expect(specialist.group_count_appraisal_by_month[0][:data]).to eq([[month, 1]])
    end
  end
end
