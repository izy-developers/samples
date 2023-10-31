# frozen_string_literal: true

RSpec.shared_context 'specialists leads' do
  def click_on_item_link
    visit '/items'
    first('.list_item_container').click
    expect(page).to have_css('#auction-house-appraisal')
  end

  def fill_in_auction_house_appraisal_description(type)
    fill_in :auction_house_appraisal_description, with: FFaker::Lorem.paragraph
    click_button type
  end

  def fill_in_consign_modal
    date_consigned = FFaker::Time.between(Date.today, Date.today + 30.days)
    fill_in :consignment_item_date_consigned, with: date_consigned.strftime('%m/%d/%Y')
    fill_in :consignment_item_min_estimate, with: FFaker::Random.rand(100..200)
    fill_in :consignment_item_max_estimate, with: FFaker::Random.rand(200..300)
    fill_in :consignment_item_proposed_auction_date, with: (date_consigned + 7.days).strftime('%m/%d/%Y')
    find('#consignment_item_specialist_agree').click
  end
end
