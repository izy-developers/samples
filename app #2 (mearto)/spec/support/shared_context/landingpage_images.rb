# frozen_string_literal: true

RSpec.shared_context 'landingpage images' do
  before do
    @landingpage = FactoryBot.create(:landingpage)
    visit "/admin/landingpages/#{@landingpage.slug}/edit"
    find('.has_many_add').click
    page.attach_file('landingpage[landingpage_images_attributes][0][image]', Rails.root + 'spec/support/test_files/example.png')
    first('#landingpage_submit_action').click
  end

  let (:landingpage) { @landingpage }
end
