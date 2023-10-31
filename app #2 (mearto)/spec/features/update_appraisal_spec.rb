# frozen_string_literal: true

require 'rails_helper'

describe 'Spec for update appraisal', type: :feature, js: true, driver: :headless_chrome do
  include_context 'authorized specialist'
  include_context 'fill in appraisal form'

  let(:seller) { FactoryBot.create(:user, :seller) }
  let!(:item)  { FactoryBot.create(:item, :create, seller_id: seller.id, assigned_to: user.id) }
  let!(:appraisal) { FactoryBot.create(:mearto_appraisal, item_id: item.id, specialist_id: user.id) }
  let!(:currency) { create(:currency) }

  before { visit '/specialist/items/' + item.slug }

  it 'should show form' do
    find('.edit_appraisal').click
    expect(page).to have_css("#edit_mearto_appraisal_#{appraisal.id}")
  end

  it 'should update appraisal' do
    find('.edit_appraisal').click
    update_appraisal(20, "#edit_mearto_appraisal_#{appraisal.id}")
    expect(page).to have_content 'Mearto appraisal was successfully updated.'
  end
end
