# frozen_string_literal: true

require 'rails_helper'
require 'securerandom'

SanitizeEmail::Config.configure do |config|
  config[:sanitized_to] = 'testadmin@mearto.com'
  config[:sanitized_cc] = 'testadmin@mearto.com'
  config[:sanitized_bcc] = 'testadmin@mearto.com'
end

def send_reset_password_form(user)
  visit '/users/password/new'
  within '.justify-content-center' do
    fill_in :user_email, with: user.email
    click_button 'Submit'
  end
end

def visit_link_from_email
  email = ActionMailer::Base.deliveries.last
  path_regex = %r{(?:"https?\://.*?)(/.*?)(?:")}
  path = email.body.match(path_regex)[1]
  visit(path)
end

def fill_new_password_form
  new_password = SecureRandom.hex(8)
  within '.new_user' do
    fill_in  :user_password, with: new_password
    fill_in  :user_password_confirmation, with: new_password
    click_button 'Change my password'
  end
end

describe 'Spec for Reset Password', type: :feature do
  let(:channel) { FactoryBot.create(:channel) }

  before(:each) { channel }

  context 'uncorrect email' do
    it 'should fail' do
      send_reset_password_form(FactoryBot.build(:user, :seller))
      expect(page).to have_content 'Email not found'
    end
  end

  context 'correct email' do
    it 'should success' do
      send_reset_password_form(FactoryBot.create(:user, :seller))
      visit_link_from_email
      fill_new_password_form
      expect(page).to have_content 'Your password has been changed successfully.'
    end
  end
end
