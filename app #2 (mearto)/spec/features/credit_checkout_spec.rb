# frozen_string_literal: true

require 'rails_helper'

describe 'Spec for stripe', type: :feature, js: true, driver: :headless_chrome do
  include_context 'authorized user'
  include_context 'fill in item form'

  let(:item) { FactoryBot.create(:item, :stripe, seller_id: user.id) }
  let(:item_image) { FactoryBot.create(:item_image, item_id: item.id) }
  let(:credit_one) { FactoryBot.create(:credit, seller_id: user.id) }
  let(:credit_two) { FactoryBot.create(:credit, seller_id: user.id) }

  context 'charges page' do
    before do
      credit_one
      visit "/items/#{item.slug}/charges/new"
    end

    it 'should show credits count' do
      expect(page).to have_content('You have 1 credits on your account')
    end

    context 'buy with credit' do
      before do
        Money.add_rate('USD', 'DKK', 6.52727)
        item_image
        find('#pay-credit-button').click
        expect(page).to have_current_path("/items/#{item.slug}/charges/pay_with_credit", only_path: true)
      end

      it 'should create Invoice' do
        expect(Invoice.find_by(credit_id: credit_one.id).present?).to eq true
      end

      it 'should create AppraisalPayment' do
        expect(AppraisalPayment.count).to eq 1
      end

      it 'should marked credit as used' do
        expect(Credit.find(credit_one.id).used).to eq true
      end
    end
  end

  context 'without credits' do
    it 'should redirect to charges page' do
      attach_image_for_payment(item)
      find('#payment-button').click
      expect(page).to have_current_path('/seller/credits/new', only_path: true)
    end
  end

  context 'with credits' do
    before do
      Money.add_rate('USD', 'DKK', 6.52727)
      credit_one
    end

    it 'should redirect to charges page' do
      attach_image_for_payment(item)
      find('#pay-credit-button').click
      expect(page).to have_current_path("/items/#{item.slug}/charges/pay_with_credit", only_path: true)
    end

    it 'should redirect to credits page' do
      item.update(response_time: 24)
      attach_image_for_payment(item)
      find('#payment-button').click
      expect(page).to have_current_path('/seller/credits/new', only_path: true)
    end

    it 'should redirect to charges page' do
      item.update(response_time: 24)
      credit_two
      attach_image_for_payment(item)
      find('#pay-credit-button').click
      expect(page).to have_current_path("/items/#{item.slug}/charges/pay_with_credit", only_path: true)
    end
  end
end
