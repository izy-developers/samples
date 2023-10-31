# frozen_string_literal: true

require 'rails_helper'

def refund(seller)
  visit "/admin/sellers/#{seller.id}"
  find('a', text: 'Refund').click
end

def choose_credits_count
  within '#popular' do
    find('a').click
  end
  expect(page).to have_current_path('/seller/credits/checkout', only_path: true)
end

def create_credit_invoice
  visit '/seller/credits/new'
  choose_credits_count
  send_stripe_form('4242424242424242', '123456')
  expect(page).to have_current_path('/seller/credits', only_path: true)
  expect(Invoice.find_by(user_id: user.id).present?).to eq true
end

describe 'Spec for refund amount for credits', type: :feature, js: true, driver: :headless_chrome do
  include_context 'authorized user'
  include_context 'authorized admin'
  include_context 'fill in stripe form'

  it "shouldn't show invoice" do
    create_credit_invoice
    refund(user)
    expect(page).to have_content('Money has been refunded!')
    expect(Invoice.credits_invoces_without_refund.count).to eq 0
  end

  it 'should create refund' do
    create_credit_invoice
    refund(user)
    expect(page).to have_content('Money has been refunded!')
    expect(Refund.count).to eq 1
  end
end
