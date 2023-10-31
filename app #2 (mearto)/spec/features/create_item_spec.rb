# frozen_string_literal: true

require 'rails_helper'

describe 'Spec for create items', type: :feature, js: true, driver: :headless_chrome do
  include_context 'authorized user'
  include_context 'fill in item form'
  let(:item) { FactoryBot.build(:item) }
  let!(:category) { FactoryBot.create(:category) }
  let!(:currency) { create(:currency) }

  before { visit '/items/new' }

  context 'correct details' do
    it 'should go to step2' do
      choose_category
      expect(page).to have_css('#step-2')
    end

    it 'should go to step3' do
      choose_category
      fill_in_title_description(item)
      expect(page).to have_css('#step-3')
    end

    it 'should go to step4' do
      choose_category
      fill_in_title_description(item)
      fill_in_provenance(item)
      expect(page).to have_css('#step-4')
    end

    it 'should success' do
      choose_category
      fill_in_title_description(item)
      fill_in_provenance(item)
      needs_appraisal?(true)
      click_finish_button
      expect(page).to have_content 'Please add at least 4 images of your item from various angles'
    end

    it 'without appraisal' do
      choose_category
      fill_in_title_description(item)
      fill_in_provenance(item)
      needs_appraisal?(false)
      set_asking_price_and_finish
      expect(page).to have_content 'Please add at least 4 images of your item from various angles'
    end
  end
end
