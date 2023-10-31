# frozen_string_literal: true

require 'rails_helper'

describe 'Spec for upload item image', type: :feature, js: true, driver: :headless_chrome, js_logs: true do
  include_context 'authorized user'
  include_context 'upload image'
  let(:item) { FactoryBot.create(:item, :stripe, seller_id: user.id) }

  context 'with correct format' do
    it 'should have uploaded images' do
      upload_image(item, 'png')
      expect(page).to have_css('#uploaded_images')
      expect(ItemImage.where(item_id: item.id).count).to eq 1
    end
  end

  context 'with incorrect format' do
    it 'should have error message' do
      upload_image(item, 'pdf')
      expect(page).to have_css('#file-name')
    end
  end
end
