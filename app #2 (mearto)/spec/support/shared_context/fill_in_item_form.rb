# frozen_string_literal: true

RSpec.shared_context 'fill in item form' do
  def choose_category
    first('.parent-category').click
    click_button 'Next'
  end

  def fill_in_title_description(item)
    fill_in :item_title, with: item.title
    fill_in :item_description, with: item.description
    click_button 'Next'
  end

  def fill_in_provenance(item)
    fill_in :item_provenance, with: item.provenance
    click_button 'Next'
  end

  def needs_appraisal?(option)
    find("#appraisal_question_#{option}").click
    click_button 'Next'
  end

  def click_finish_button
    choose('Yes') # mark item for sale
    click_button 'Finish'
  end

  def set_asking_price_and_finish
    fill_in 'item_asking_price', with: '100'
    select('USD', from: 'item_currency')
    check :item_marketplace_terms_of_service
    click_button 'Finish'
  end

  def fill_in_description(artist)
    fill_in 'item_description', with: artist.name
    find('#btn-step-2').click
  end

  def fill_in_ebay_description(item)
    fill_in 'ebay_item_description', with: item.description
    fill_in 'ebay_item_ebay_url', with: item.ebay_url
    find('#check-ebay-item').click
    expect(page).to have_css('#btn-step-2')
    find('#btn-step-2').click
  end

  def attach_item_files(format)
    page.attach_file('item-files', Rails.root + "spec/support/test_files/example.#{format}")
    if format == 'png'
      expect(page).to have_css('.img-thumbnail')
      find('#btn-step-3').click
    end
  end

  def fill_in_registration_form(user, password = nil)
    within '#registration' do
      fill_in :user_email_signup, with: user.email
      fill_in :user_password_signup, with: user.password if password.present?
      fill_in :user_full_name, with: "#{user.first_name} #{user.last_name}"
      fill_in :user_address, with: user.address
      click_button 'Finish'
    end
  end

  def fill_in_login_form(user)
    find('#login-link').click
    within '#login-form' do
      fill_in :user_email_login, with: user.email
      fill_in :user_password_login, with: user.password
      find('.btn-login').click
    end
  end

  def fill_in_artist
    visit '/authenticate'
    fill_in 'artist', with: FFaker::Lorem.word
    find('#btn-step-1').click
  end

  def fill_in_material_description
    fill_in 'dimensions_material', with: FFaker::Lorem.word
    fill_in 'stamps', with: FFaker::Lorem.word
    fill_in 'description', with: FFaker::Lorem.word
    find('#btn-step-2').click
  end

  def fill_in_acquired_and_provenance
    fill_in 'acquired', with: FFaker::Lorem.word
    fill_in 'provenance', with: FFaker::Lorem.word
    find('#btn-step-3').click
  end

  def attach_files_for_authenticate(format)
    page.attach_file('item-files', Rails.root + "spec/support/test_files/example.#{format}")
    if format == 'png'
      expect(page).to have_css('.img-thumbnail')
      find('#btn-step-4').click
    end
  end

  def attach_image_for_payment(item)
    visit "/items/#{item.slug}/item_images/new"
    page.attach_file('item_image_attachments', Rails.root + 'spec/support/test_files/example.png')
    expect(page).to have_css('.img-thumbnail')
    visit "/items/#{item.slug}"
  end
end
