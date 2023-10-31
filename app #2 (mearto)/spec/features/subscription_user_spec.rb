# frozen_string_literal: true

require 'rails_helper'

describe 'Spec for subscription user', type: :feature, js: true, driver: :headless_chrome do
  include_context 'authorized user'
  include_context 'fill in stripe element'
  let!(:plan) { FactoryBot.create(:plan, :premium) }

  context 'valid payment details' do
    it 'should success' do
      send_stripe_form('4242424242424242', '123456')
      sleep 3
      expect(page).to have_content('Thank you for becoming a member of Mearto.')
    end
  end

  context 'invalid  payment details ' do
    it "shouldn't success" do
      send_stripe_form('2424242424242424', '', false)
      expect(page).to have_content 'Your card number is invalid.'
    end
  end
end
