# frozen_string_literal: true

require 'rails_helper'

describe 'Spec for specialist', type: :feature do
  include_context 'authorized specialist'
  include_context 'fill in user edit form'

  context 'update data' do
    it 'should success with correct details' do
      send_user_update_form(user, true)
      expect(page).to have_content 'Your info was successfully updated'
    end
  end

  context 'update password' do
    it 'should fail with incorrect password confirmation' do
      old_password = user.password.reverse
      send_changed_password_form(user, old_password, true)
      expect(page).to have_css('#error_explanation')
    end

    it 'should fail without current password' do
      old_password = user.password
      send_changed_password_form(user, old_password)
      expect(page).to have_css('#error_explanation')
    end

    it 'should success with correct details' do
      old_password = user.password
      send_changed_password_form(user, old_password, true)
      expect(page).to have_content 'Your password was successfully updated'
    end
  end
end
