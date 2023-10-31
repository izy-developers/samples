# frozen_string_literal: true

require 'rails_helper'

describe 'Spec for estimate an item', type: :feature do
  include_context 'authorized specialist'
  include_context 'fill in appraisal form'

  let(:specialist) { FactoryBot.create(:user, :specialist) }
  let(:seller) { FactoryBot.create(:user, :seller) }
  let!(:item)  { FactoryBot.create(:item, :create, seller_id: seller.id, assigned_to: specialist.id) }

  context 'unassigned item' do
    it "shouldn't be able to add an appraisal" do
      visit '/specialist/items/' + item.slug
      expect(page).to have_content 'This item has been assigned to'
    end
  end

  context 'assigned item' do
    before do
      item.update(assigned_to: user.id)
      visit '/specialist/items/' + item.slug
    end

    it 'should success' do
      fill_appraisal_form(20, 'Send')
      expect(page).to have_css('.appraisal-body')
    end

    it 'should fail' do
      fill_appraisal_form(0, 'Send')
      expect(page).to have_content 'The specialist needs more information'
    end
  end
end
