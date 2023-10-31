# frozen_string_literal: true

require 'rails_helper'

describe 'Spec for specialist message template', type: :feature, js: true, driver: :headless_chrome do
  let!(:seller) { FactoryBot.create(:seller, :mearto_channel) }
  let!(:item) { FactoryBot.create(:item, seller_id: seller.id) }
  let!(:appraisal_payment) { FactoryBot.create(:appraisal_payment, seller_id: seller.id, item_id: item.id) }
  let(:template) { FactoryBot.create(:specialist_template, specialist_id: user.id) }

  include_context 'authorized specialist'

  before do
    visit '/specialist/choose_items'
    expect(page).to have_content(item.title)
    click_button 'Assign me'
    expect(page).to have_content("You have been assigned to item '#{item.title}'")
    visit "/specialist/items/#{item.slug}"
    expect(page).to have_css('#templates')
    expect(find_link('New Template').visible?).to eq(true)
  end

  it 'should create template and mail' do
    Sidekiq::Queues['mailers'].clear
    click_link 'New Template'
    expect(page).to have_content('Create New Template')
    fill_in :specialist_template_title, with: FFaker::Lorem.word.capitalize
    fill_in :specialist_template_text, with: FFaker::Lorem.paragraph
    click_button 'Create'
    expect(page).to have_content('New template was successfully created. Please wait for confirmation.')
    expect(SpecialistTemplate.count).to eq(1)
  end

  it 'should not display not approved template' do
    template
    visit "/specialist/items/#{item.slug}"
    expect(SpecialistTemplate.count).to eq(1)
    expect(page).to_not have_link(template.title)
  end

  it 'should display not approved template in Manage Templates page' do
    template
    visit '/specialist_template'
    expect(page).to have_content('List of Your Message Templates:')
    expect(page).to have_content(template.title)
    expect(page).to have_content('Not yet approved')
  end

  it 'should display approved template in the message' do
    template.update(approved: true)
    visit "/specialist/items/#{item.slug}"
    expect(page).to have_link(template.title)
    expect(page).to_not have_content(template.text)
    click_link template.title
    click_button 'Send'
    expect(page).to have_content(template.text)
  end
end
