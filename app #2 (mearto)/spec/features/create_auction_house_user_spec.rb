# frozen_string_literal: true

require 'rails_helper'

describe 'Spec for create auction house user', type: :feature, js: true, driver: :headless_chrome do
  include_context 'authorized specialist'
  include_context 'fill in auction house user form'

  let(:user) { FactoryBot.create(:auction_house_user) }

  it 'should show error' do
    fill_in_auction_house_user_form_first_step(user, user.organisation.slug, phone: '')
    expect(page).to have_content "Phone can't be blank"
  end

  it 'should success' do
    fill_in_auction_house_user_form_first_step(user, user.organisation.slug, phone: '123456789')
    fill_in_auction_house_user_form_next_steps
    expect(page).to have_content 'Your request has been forwarded. Thank you!'
  end
end
