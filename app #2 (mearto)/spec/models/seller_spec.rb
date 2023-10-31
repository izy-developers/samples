# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Seller, type: :model do
  context 'Test validation' do
    it 'should be valid' do
      expect(FactoryBot.build(:seller)).to be_valid
    end
  end

  context 'Test method' do
    it 'country_should success' do
      expect(FactoryBot.build(:seller).country.data).to eq(Country.new('AD').data)
    end

    it 'country_should nil' do
      expect(FactoryBot.build(:seller, :no_country).country).to be_nil
    end

    it 'country_name should return name' do
      expect(FactoryBot.build(:seller).country.data.name).to eq('Andorra')
    end

    it 'country_name should return adress' do
      seller = FactoryBot.build(:seller, :no_country)
      expect(seller.country_name).to eq(seller.address)
    end

    it 'is_from_whitelabel? should return true' do
      expect(FactoryBot.build(:seller, :other_channel).is_from_whitelabel?).to be true
    end

    it 'is_from_whitelabel? should return false' do
      expect(FactoryBot.build(:seller, :mearto_channel).is_from_whitelabel?).to be false
    end
  end

  context 'Test association' do
    it 'should have many items' do
      expect(Seller.reflect_on_association(:items).macro).to eq(:has_many)
    end

    it 'should have many subscriptions' do
      expect(Seller.reflect_on_association(:subscriptions).macro).to eq(:has_many)
    end

    it 'should have many plans' do
      expect(Seller.reflect_on_association(:plans).macro).to eq(:has_many)
    end

    it 'should have many appraisal_payments' do
      expect(Seller.reflect_on_association(:appraisal_payments).macro).to eq(:has_many)
    end
  end
end
