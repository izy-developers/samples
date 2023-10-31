# frozen_string_literal: true

RSpec.shared_context 'fill in stripe form' do
  def send_stripe_form(card, postal = nil)
    find('#show-card-input').click
    expect(page).to have_css('#card-element')
    iframe = find('iframe[title="Secure card payment input frame"]')

    Capybara.within_frame iframe do
      send_keys_with_delay('cardnumber', card)
      send_keys_with_delay('exp-date', '1222')
      send_keys_with_delay('cvc', '123')
      send_keys_with_delay('postal', postal) if postal
    end
    find('#submit_button').click
  end

  def fill_in_code(code)
    find('#show_discount_form').click
    fill_in :'discount-code', with: code
    find('#apply-code').click
  end
end
