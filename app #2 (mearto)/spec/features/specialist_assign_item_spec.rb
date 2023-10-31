# frozen_string_literal: true

require 'rails_helper'

describe 'Spec for assign item by specialist', type: :feature, js: true, driver: :headless_chrome do
  let!(:seller) { FactoryBot.create(:seller, :mearto_channel) }
  let!(:item) { FactoryBot.create(:item, seller_id: seller.id) }
  let!(:appraisal_payment) { FactoryBot.create(:appraisal_payment, seller_id: seller.id, item_id: item.id) }
  let!(:another_specialist) { FactoryBot.create(:specialist) }
  let!(:assigned_item) { FactoryBot.create(:item, seller_id: seller.id, assigned_to: another_specialist.id) }

  include_context 'authorized specialist'

  it "should display 'Assign me' button on Book Item page" do
    expect(item.assigned_to).to eq(nil)
    expect(page).to have_content(item.title)
    expect(page).to have_selector(:link_or_button, 'Assign me')
  end

  it "should display 'Assign me' button on item page" do
    visit '/specialist/items/' + item.slug
    expect(item.assigned_to).to eq(nil)
    expect(page).to have_content('This item has not been assigned yet')
    expect(page).to have_selector(:link_or_button, 'Assign me')
  end

  it "shouldn't display 'Assign me' button for assigned item" do
    expect(assigned_item.assigned_to).to_not eq(nil)
    visit '/specialist/items/' + assigned_item.slug
    expect(page).to have_content("This item has been assigned to #{another_specialist.fullname}")
    expect(page).to_not have_selector(:link_or_button, 'Assign me')
  end

  it 'should assign item' do
    visit '/specialist/items/' + item.slug
    expect(item.assigned_to).to eq(nil)
    expect(page).to have_content('This item has not been assigned yet')
    expect(page).to have_selector(:link_or_button, 'Assign me')
    click_button 'Assign me'
    expect(page).to have_content("You have been assigned to item '#{item.title}'")
    item.reload
    expect(item.assigned_at).to_not eq(nil)
  end

  context 'colored boxes' do
    before(:each) do
      assigned_items = user.assigned_items.is_paid.where(state: [:open])
      item.update(assigned_to: user.id, assigned_at: DateTime.now) # assign item to specialist
      expect(assigned_items.reload.count).to eq(1)
      visit '/specialist/my_items'
      expect(page).to have_css('.item-container')
    end

    it 'should display assigned item without colored border' do
      border_css = page.find('.item-container').native.css_value('border')
      expect(border_css).to eq('0px none rgb(149, 152, 158)')
    end

    it 'should display assigned item with red colored border' do
      item.update_attribute(:assigned_at, DateTime.now - 42.hours)
      visit '/specialist/my_items'
      border_css = page.find('.item-container').native.css_value('border')
      expect(border_css).to eq('3px solid rgb(255, 0, 0)')
    end

    it 'should display assigned item with yellow colored border' do
      item.update_attribute(:assigned_at, DateTime.now - 36.hours)
      visit '/specialist/my_items'
      border_css = page.find('.item-container').native.css_value('border')
      expect(border_css).to eq('3px solid rgb(255, 255, 0)')
    end

    it 'should display assigned item (24 hours) with red colored border' do
      item.update(response_time: 24, assigned_at: DateTime.now - 20.hours)
      visit '/specialist/my_items'
      border_css = page.find('.item-container').native.css_value('border')
      expect(border_css).to eq('3px solid rgb(255, 0, 0)')
    end

    it 'should display assigned item (24 hours) with yellow colored border' do
      item.update(response_time: 24, assigned_at: DateTime.now - 12.hours)
      visit '/specialist/my_items'
      border_css = page.find('.item-container').native.css_value('border')
      expect(border_css).to eq('3px solid rgb(255, 255, 0)')
    end
  end
end
