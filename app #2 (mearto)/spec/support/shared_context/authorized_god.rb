# frozen_string_literal: true

RSpec.shared_context 'authorized god' do
  before do
    @user = FactoryBot.create(:god)
    visit '/users/sign_in'
    within '.new_user' do
      fill_in :user_email, with: @user.email
      fill_in :user_password, with: @user.password
      click_button 'Log in'
    end
  end

  let (:user) { @user }
end
