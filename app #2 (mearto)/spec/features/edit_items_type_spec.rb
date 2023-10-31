# frozen_string_literal: true

require 'rails_helper'

describe 'Spec for edit type an item', type: :feature, js: true, driver: :headless_chrome do
  include_context 'authorized specialist'
  include_context 'fill in appraisal form'

  let(:specialist) { FactoryBot.create(:user, :specialist) }
  let(:seller) { FactoryBot.create(:user, :seller) }
  let!(:item)  { FactoryBot.create(:item, :create, seller_id: seller.id, assigned_to: specialist.id) }
  let!(:second_category) { FactoryBot.create(:category, :second) }

  context 'unassigned item' do
    it "shouldn't be able to edit" do
      visit '/specialist/items/' + item.slug
      expect(page).to have_content 'This item has been assigned to'
    end
  end

  context 'assigned item' do
    it 'should success' do
      item.update(assigned_to: user.id)
      visit '/specialist/items/' + item.slug
      select second_category.name.capitalize, from: 'item_category_id'
      within '#category-form' do
        click_button 'Update'
      end
      expect(page).to have_content 'Success'
    end
  end
end
