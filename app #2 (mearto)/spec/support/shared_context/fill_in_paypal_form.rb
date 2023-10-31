# frozen_string_literal: true

RSpec.shared_context 'fill in paypal form' do
  def send_paypal_form
    popup = window_opened_by do
      find('#paypal-button').click
    end
    within_window(popup) do
      expect(page).to have_css('#email')
    end
    popup
  end

  def fill_fail_form(popup)
    within_window(popup) do
      fill_paypal_sign_in_form('password')
    end
  end

  def fill_success_form(popup)
    within_window(popup) do
      fill_paypal_sign_in_form('123456789')
      expect(page).to have_css('#confirmButtonTop')
      click_button 'confirmButtonTop'
    end
  end

  def fill_paypal_sign_in_form(password)
    fill_in :email, with: 'jl-buyer@mearto.com'
    click_button 'Next'
    fill_in :password, with: password
    click_button 'btnLogin'
  end
end
