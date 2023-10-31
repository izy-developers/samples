# frozen_string_literal: true

require 'rails_helper'

def set_category(landingpage, fail = false)
  visit "/admin/landingpages/#{landingpage.slug}/edit"
  expect(page).to have_css('.select2')
  find('.select2').click
  if fail
    expect(page).to have_content('No results found')
  else
    first('.select2-results__option').click
    first('#landingpage_submit_action').click
    expect(page).to have_content('Landingpage was successfully updated.')
  end
end

describe 'Spec for merge landingpage and category', type: :feature, js: true, driver: :headless_chrome do
  let!(:channel) { FactoryBot.create(:channel) }
  include_context 'authorized admin'
  let(:category) { FactoryBot.create(:category) }
  let!(:landingpage) { FactoryBot.create(:landingpage) }
  let!(:image_first) { FactoryBot.create(:landingpage_image, landingpage_id: landingpage.id) }

  context 'landingpage changes' do
    it "shouldn't set category" do
      set_category(landingpage, true)
    end

    it "shouldn't set category" do
      category.update(description2: landingpage.description)
      set_category(landingpage, true)
    end

    it 'should set category' do
      category
      set_category(landingpage)
    end
  end

  context 'category changes' do
    before(:all) { Sidekiq::Testing.inline! }
    after(:all) { Sidekiq::Testing.fake! }

    before do
      category
      set_category(landingpage)
    end

    it 'should changed description2' do
      expect(Category.find(category.id).description2).to eq(Landingpage.find(landingpage.id).description)
    end

    it 'should changed faq' do
      expect(Category.find(category.id).faq).to eq(Landingpage.find(landingpage.id).faq)
    end

    it 'should create category images' do
      expect(Category.find(category.id).category_images.count).to eq(1)
    end
  end
end
