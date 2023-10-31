# frozen_string_literal: true

RSpec.shared_context 'authorized admin' do
  before do
    @admin = create(:admin_user)
    visit '/admin/login'
    within '#session_new' do
      fill_in :admin_user_email, with: @admin.email
      fill_in :admin_user_password, with: @admin.password
      click_button 'Login'
    end
  end

  let (:admin) { @admin }
end
