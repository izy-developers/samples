# frozen_string_literal: true

require 'rails_helper'

def fill_in_item_edit_form(description = nil)
  within '.edit_item' do
    fill_in :item_description, with: description || '  '
    click_button 'Update'
  end
end

describe 'Spec for edit item', type: :feature do
  include_context 'authorized user'
  let!(:item) { FactoryBot.create(:item, :create, seller_id: user.id) }
  let(:description) { FFaker::Lorem.paragraph }

  before { visit "/items/#{item.slug}/edit" }

  it "shouldn't update item" do
    fill_in_item_edit_form
    expect(page).to have_css('#error_explanation')
  end

  it 'should update item' do
    fill_in_item_edit_form(description)
    expect(page).to have_content('Item was successfully updated.')
    expect(Item.find(item.id).description).to eq description
  end
end
