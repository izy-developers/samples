# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AuctionHouseUser, type: :model do
  context 'Test validation' do
    it 'should be valid' do
      expect(FactoryBot.build(:auction_house_user)).to be_valid
    end
  end
  context 'Test ascociation' do
    it 'should belongs to organisation' do
      expect(AuctionHouseUser.reflect_on_association(:organisation).macro).to eq(:belongs_to)
    end

    it 'should have many auction_house_user_images' do
      expect(AuctionHouseUser.reflect_on_association(:auction_house_user_images).macro).to eq(:has_many)
    end
  end

  context 'Test method' do
    let(:user) { FactoryBot.create(:auction_house_user) }

    it 'upload_image_to_email should be true' do
      file = File.open(Rails.root + 'spec/support/test_files/example.png')
      expect(user.upload_image_to_email(file, 'example.png')).to eq(user.auction_house_user_images.last)
    end
  end
end
