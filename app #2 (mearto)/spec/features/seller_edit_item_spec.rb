# frozen_string_literal: true

require 'rails_helper'

describe 'Spec for seller edit item', type: :feature, js: true, driver: :headless_chrome do
  include_context 'authorized user'
  include_context 'fill in item edit form'
  let(:item) { FactoryBot.create(:item, :create, seller_id: user.id) }

  context 'title' do
    it 'should success' do
      fill_update_item_form_input(item.slug, 'item_title', item.title.reverse)
      expect(page).to have_content 'Item was successfully updated.'
    end

    it 'should fail' do
      fill_update_item_form_input(item.slug, 'item_title', '')
      expect(page).to have_content 'Edit your item'
    end
  end

  context 'description' do
    it 'should success' do
      fill_update_item_form_input(item.slug, 'item_description', item.description.reverse)
      expect(page).to have_content 'Item was successfully updated.'
    end

    it 'should fail' do
      fill_update_item_form_input(item.slug, 'item_description', '')
      expect(page).to have_content 'Edit your item'
    end
  end
end
