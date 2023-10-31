# frozen_string_literal: true

require 'rails_helper'

describe 'Spec for send emails to specialist after upload new images', type: :feature, js: true, driver: :headless_chrome do
  include_context 'authorized user'
  include_context 'upload image'
  let!(:item) { FactoryBot.create(:item, :stripe, seller_id: user.id) }
  let!(:specialist) { FactoryBot.create(:specialist) }
  let!(:appraisal) { FactoryBot.create(:mearto_appraisal, item_id: item.id, specialist_id: specialist.id) }

  context 'upload one image' do
    it 'should have one email' do
      ActiveJob::Base.queue_adapter = :test
      send_mail(item)
      expect { MessageMailer.notify_appraiser_about_new_images(item, appraisal).deliver_later }.to have_enqueued_job.on_queue('mailers')
    end
  end

  context 'upload two images' do
    it 'should have one email' do
      ActiveJob::Base.queue_adapter = :test
      send_mail(item, true)
      expect { MessageMailer.notify_appraiser_about_new_images(item, appraisal).deliver_later }.to have_enqueued_job.on_queue('mailers')
    end
  end
end
