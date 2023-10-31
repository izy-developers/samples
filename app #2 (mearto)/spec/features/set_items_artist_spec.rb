# frozen_string_literal: true

require 'rails_helper'

def choose_item_artist(artist)
  expect(page).to have_css('.select2')
  find('.select2').click
  find('.select2-search__field').set(artist.name)
  expect(page).to have_css('.search-result')
  first('.search-result').click
  within '#artist-form' do
    click_button 'Update'
  end
end

describe 'Spec for set item artist', type: :feature, js: true, driver: :headless_chrome do
  include_context 'authorized specialist'

  let(:specialist) { FactoryBot.create(:user, :specialist) }
  let(:seller) { FactoryBot.create(:user, :seller) }
  let!(:item)  { FactoryBot.create(:item, :create, seller_id: seller.id, assigned_to: specialist.id) }
  let!(:artist) { FactoryBot.create(:artist) }

  context 'unassigned item' do
    it "shouldn't be able to edit" do
      visit '/specialist/items/' + item.slug
      expect(page).to have_content 'This item has been assigned to'
    end
  end

  context 'assigned item' do
    before do
      item.update(assigned_to: user.id)
      visit '/specialist/items/' + item.slug
      choose_item_artist(artist)
    end

    it 'should show success' do
      expect(page).to have_content 'Success'
    end

    it 'should set artist' do
      expect(page).to have_content 'Success'
      expect(Item.find(item.id).artist).to eq artist
    end
  end
end
