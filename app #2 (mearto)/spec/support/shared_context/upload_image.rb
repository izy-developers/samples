# frozen_string_literal: true

RSpec.shared_context 'upload image' do
  def upload_image(item, format)
    visit "/items/#{item.slug}/item_images/new"
    page.attach_file('item_image_attachments', Rails.root + "spec/support/test_files/example.#{format}")
    sleep 10
  end

  def send_mail(item, twice = false)
    Sidekiq::Queue.new('mailers').clear
    upload_image(item, 'png') if twice
    upload_image(item, 'png')
    expect(page).to have_css('#uploaded_images')
    sleep 10
  end
end
