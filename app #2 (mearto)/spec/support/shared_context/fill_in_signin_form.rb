# frozen_string_literal: true

RSpec.shared_context 'fill in sign in form' do
  def send_signin_form(user, password = nil)
    visit '/users/sign_in'
    within '.new_user' do
      fill_in :user_email, with: user.email
      fill_in :user_password, with: user.password if password.present?
      click_button 'Log in'
    end
  end
end
