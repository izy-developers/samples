# frozen_string_literal: true

RSpec.shared_context 'fill in stripe element' do
  def send_stripe_form(card, postal = nil, submit = true)
    visit('/subscriptions/new?s=premium')
    expect(page).to have_css('#card-element')
    stripe_div = find('.__PrivateStripeElement')
    iframe = stripe_div.find('iframe:first-child')
    within_frame iframe do
      find_field('Card number').send_keys(card)
      find_field('MM / YY').send_keys("01#{(DateTime.now.year + 1).to_s.last(2)}")
      find_field('CVC').send_keys('123')
      find_field('ZIP').send_keys(postal) if postal.present?
    end

    click_button 'Submit Payment' if submit
  end
end
