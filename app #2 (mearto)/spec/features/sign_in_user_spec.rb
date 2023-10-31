# frozen_string_literal: true

require 'rails_helper'

describe 'Spec for Sign In', type: :feature do
  include_context 'fill in sign in form'
  let(:user) { FactoryBot.create(:user, :seller) }

  context 'without password' do
    it 'should fail' do
      send_signin_form(user)
      expect(page).to have_content 'Log in'
    end
  end

  context 'with password' do
    it 'should success' do
      send_signin_form(user, true)
      expect(page).to have_current_path('/seller/collection', only_path: true)
    end
  end
end
