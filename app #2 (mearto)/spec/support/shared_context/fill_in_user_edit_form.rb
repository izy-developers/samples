# frozen_string_literal: true

RSpec.shared_context 'fill in user edit form' do
  def send_user_update_form(user, valid = false)
    type = user.type.downcase
    visit "/#{user.type.downcase}/edit"
    within "#edit_#{user.type.downcase}" do
      first_name = valid.present? ? FFaker::Name.first_name : ''
      last_name = valid.present? ? FFaker::Name.last_name : ''
      fill_in :"#{type}_first_name", with: first_name
      fill_in :"#{type}_last_name", with: last_name
      click_button 'Update'
    end
  end

  def send_changed_password_form(user, password, valid = false)
    type = user.type.downcase
    new_password = SecureRandom.hex(4)
    confirmation = valid.present? ? new_password : new_password.reverse
    visit "/#{type}/edit"
    within "#edit_#{type}_#{user.id}" do
      fill_in :"#{type}_password", with: new_password
      fill_in :"#{type}_password_confirmation", with: confirmation
      fill_in :"#{type}_current_password", with: password
      click_button 'Update'
    end
  end
end
