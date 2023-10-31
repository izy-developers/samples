# frozen_string_literal: true

require 'rails_helper'

describe 'Spec for send information from authenticate page', type: :feature, js: true, driver: :headless_chrome do
  include_context 'fill in item form'
  let!(:channel) { FactoryBot.create(:channel) }
  let(:user) { FactoryBot.build(:user, :seller) }

  context 'fill in item form' do
    it 'should go to step2' do
      fill_in_artist
      expect(page).to have_css('#step-2')
    end

    it 'should go to step3' do
      fill_in_artist
      fill_in_material_description
      expect(page).to have_css('#step-3')
    end

    it 'should go to step4' do
      fill_in_artist
      fill_in_material_description
      fill_in_acquired_and_provenance
      expect(page).to have_css('#step-4')
    end

    it "shouldn't go to step6" do
      fill_in_artist
      fill_in_material_description
      fill_in_acquired_and_provenance
      attach_files_for_authenticate('pdf')
      expect(page).to have_css('.error-message')
    end

    it 'should go to step6' do
      fill_in_artist
      fill_in_material_description
      fill_in_acquired_and_provenance
      attach_files_for_authenticate('png')
      expect(page).to have_content('Contact information')
    end
  end
end
