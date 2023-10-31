# frozen_string_literal: true

require 'rails_helper'

def choose_credits_count
  within '#popular' do
    find('a').click
  end
  expect(page).to have_content('Checkout')
end

describe 'Spec for buy bulk appraisal with Stripe', type: :feature, js: true, driver: :headless_chrome do
  include_context 'authorized user'
  include_context 'fill in stripe form'
  let(:seller) { FactoryBot.create(:user, :seller) }
  let(:users_discount) { FactoryBot.create(:users_discount, seller_id: seller.id, discount_id: own_discount.id) }

  before do
    visit '/seller/credits/new'
    choose_credits_count
  end

  context 'valid payment details' do
    it 'should show thanks page' do
      send_stripe_form('4242424242424242', '123456')
      expect(page).to have_content('Thank you')
      expect(Invoice.find_by(user_id: user.id).present?).to eq true
    end

    it 'should pay with entered card' do
      send_stripe_form('5555555555554444', '123456')
      expect(page).to have_content('Thank you')
      stripe_charge = Stripe::Charge.retrieve(Invoice.find_by(user_id: user.id).stripe_id)
      expect(stripe_charge.payment_method_details.card.last4 == '4444').to eq true
    end
  end

  context 'invalid payment details' do
    it "shouldn't success" do
      send_stripe_form('2424242424242424')
      expect(page).to have_content 'Checkout'
    end

    it "shouldn't success" do
      send_stripe_form('4242424242424242')
      expect(page).to have_content 'Checkout'
    end
  end

  context 'with discount code' do
    let(:discount) { create(:discount, kind: 'referral', value: 20, seller_id: seller.id) }
    let(:own_discount) { create(:discount, value: 50, seller_id: user.id) }

    def calculate_discount_amount(disc_value)
      5400 / 100 * (1 - disc_value.to_f / 100)
    end

    it 'should change total' do
      fill_in_code(discount.code)
      expect(page).to have_css('#total', text: "$#{calculate_discount_amount(discount.value).round(2)}")
    end

    it "shouldn't change total if use invalid discount" do
      fill_in_code(discount.code.reverse)
      expect(page).to have_css('#total', text: '54.00')
    end

    it "shouldn't change total if use own discount" do
      fill_in_code(own_discount.code)
      expect(page).to have_css('#total', text: '$54.00')
    end

    it 'should change total if use own discount after another user' do
      users_discount
      fill_in_code(own_discount.code)
      expect(page).to have_css('#total', text: "$#{calculate_discount_amount(own_discount.value)}")
    end

    it 'should create discount' do
      fill_in_code(discount.code)
      send_stripe_form('4242424242424242', '123456')
      sleep 3
      expect(page).to have_content('Thank you')
      expect(Discount.find_by(seller_id: user.id).present?).to eq true
    end
  end
end
