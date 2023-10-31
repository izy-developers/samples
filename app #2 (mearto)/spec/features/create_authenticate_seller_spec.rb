# frozen_string_literal: true

require 'rails_helper'

def create_seller
  visit '/admin/sellers/new'
  fill_in :seller_first_name, with: Faker::Name.first_name
  fill_in :seller_last_name, with: Faker::Name.last_name
  fill_in :seller_email, with: FFaker::Internet.email
  fill_in :seller_phone, with: FFaker::PhoneNumber.phone_number
  fill_in :seller_address, with: FFaker::Address.city
  fill_in :seller_country_id, with: 'US'
  select '(GMT+00:00) London', from: :seller_time_zone
  select 'mearto', from: :seller_channel_id
  fill_in :seller_password, with: '123456'
  page.evaluate_script('$("input[name=\'commit\']").attr(\'disabled\', false).css(\'background\', \'royalblue\');')
  find('input[name="commit"]').click
end

def create_item_for_seller
  Rails.cache.clear
  visit '/admin/items/new'
  select 'Maybe', from: :item_is_for_sale
  fill_in :item_title, with: FFaker::Lorem.sentence
  fill_in :item_description, with: FFaker::Lorem.paragraph
  fill_in :item_provenance, with: FFaker::Lorem.paragraph
  select 'First category', from: :item_category_id
  select 'mearto', from: :item_channel_id
  select Seller.first.email, from: :item_seller_id
  click_button 'Create Item'
end

describe 'Spec for create seller from authenticate', type: :feature, js: true, driver: :headless_chrome do
  include_context 'authorized admin'

  let!(:channel) { FactoryBot.create(:channel) }
  let!(:category) { FactoryBot.create(:category) }

  before(:each) do
    ActionMailer::Base.deliveries.clear
  end

  it 'should create seller with pass token' do
    create_seller
    expect(Seller.count).to eq(1)
  end

  it 'should create item for seller' do
    create_seller
    create_item_for_seller
    expect(Item.count).to eq(1)
    expect(Sidekiq::Queues['mailers'].size).to eq(1)
  end
end
