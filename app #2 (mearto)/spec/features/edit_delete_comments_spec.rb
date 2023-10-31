# frozen_string_literal: true

require 'rails_helper'

def add_comment
  fill_in :comment_comment, with: FFaker::Lorem.paragraph
  click_button 'Add Comment'
  expect(Comment.count).to eq(1)
end

describe 'Spec for edit/delete messages by specialist', type: :feature, js: true, driver: :headless_chrome do
  include_context 'authorized specialist'

  let!(:seller) { FactoryBot.create(:seller, :mearto_channel) }
  let!(:item) { FactoryBot.create(:item, seller_id: seller.id, assigned_to: user.id) }
  let!(:appraisal) { FactoryBot.create(:appraisal, description: FFaker::Lorem.paragraph, item_id: item.id, specialist_id: user.id, fake: true, type: 'MeartoAppraisal') }

  before do
    visit '/specialist/items/' + item.slug
  end

  it 'should show edit/delete links' do
    add_comment
    expect(page).to have_css('#edit_comment')
    expect(page).to have_css('#delete_comment')
  end

  it 'should delete message' do
    add_comment
    click_on 'delete'
    expect(page).to have_content('Comment was successfully removed.')
    expect(Comment.count).to eq(0)
    expect(page).to_not have_css('#appraisal-container-comments')
  end
end
