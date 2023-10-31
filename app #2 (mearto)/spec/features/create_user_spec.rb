# frozen_string_literal: true

require 'rails_helper'

def fill_in_step1(user, channel)
  fill_in :user_email_signup, with: user.email
  fill_in :user_password_signup, with: user.email if channel.is_whitelabel?
  click_button 'Sign Up'
  expect(page).to have_css('#step-2')
end

def send_signup_form(password = nil, full_name = nil)
  fill_in :user_password_signup, with: password
  fill_in :user_full_name, with: full_name
  select 'Germany', from: :user_country_id
  fill_in :user_address, with: 'Berlin'
  click_button 'Complete'
end

describe 'Spec for Sign Up', type: :feature, js: true, driver: :headless_chrome do
  let(:user) { FactoryBot.build(:user) }
  let(:default_channel) { FactoryBot.create(:channel) }

  before(:each) do
    default_channel
    visit '/users/sign_up'
  end

  context 'without whitelabel' do
    it 'should go to step2' do
      fill_in_step1(user, default_channel)
    end

    it "shouldn't create new user" do
      fill_in_step1(user, default_channel)
      send_signup_form('1', user.fullname)
      expect(page).to have_current_path('/users', only_path: true)
      expect(page).to have_content 'Password is too short (minimum is 6 characters)'
    end

    it "shouldn't create new user" do
      fill_in_step1(user, default_channel)
      send_signup_form('123456', 'XX')
      expect(page).to have_current_path('/users', only_path: true)
      expect(page).to have_content 'Full name should contain first name and last name'
    end

    it 'should create new user' do
      fill_in_step1(user, default_channel)
      send_signup_form('123456', user.fullname)
      expect(page).to have_current_path('/seller/collection', only_path: true)
    end
  end
end
