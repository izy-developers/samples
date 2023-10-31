# frozen_string_literal: true

require 'rails_helper'

describe 'Spec for edit item title by specialist', type: :feature, js: true, driver: :headless_chrome do
  include_context 'authorized specialist'

  let!(:seller) { FactoryBot.create(:seller, :mearto_channel) }
  let!(:item) { FactoryBot.create(:item, seller_id: seller.id, assigned_to: user.id) }

  before do
    visit '/specialist/items/' + item.slug
  end

  it 'should show edit input and buttons' do
    expect(page).to_not have_css('#submit_edit_title')
    expect(page).to_not have_css('#cancel_edit_title')
    expect(page).to_not have_css('#title-input')
    find(:css, 'i.far.fa-edit').click
    expect(page).to have_css('#submit_edit_title')
    expect(page).to have_css('#cancel_edit_title')
    expect(page).to have_css('#title-input')
  end

  it 'should successfully change item title' do
    find(:css, 'i.far.fa-edit').click
    new_title = FFaker::Lorem.words(3).join(' ')
    fill_in :edit_title, with: new_title
    click_link 'Submit'
    expect(page).to have_content(new_title)
    expect(page).to have_css('.far.fa-check-circle.edited-title')
  end
end
