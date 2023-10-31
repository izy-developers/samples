# frozen_string_literal: true

RSpec.shared_context 'fill in auction house user form' do
  def fill_in_auction_house_user_form_first_step(user, slug, options = {})
    visit "/appraisers/#{slug}"
    fill_in :auction_house_user_name, with: user.name
    fill_in :auction_house_user_email, with: user.email
    fill_in :auction_house_user_phone, with: options[:phone]
    find('#second-step').click
  end

  # organisations#show, form
  def fill_in_auction_house_user_form_next_steps
    check('auction_house_user_consignment')
    check('auction_house_user_home_estate')
    check('auction_house_user_other')
    find('#last-step').click
    fill_in :auction_house_user_description, with: FFaker::Lorem.sentence
    attach_file('auction_house_user_first_image', Rails.root + 'spec/support/test_files/example.png')
    find('#submit').click
  end
end
