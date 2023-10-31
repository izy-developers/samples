require 'benchmark'
class ScraperdataJob < ApplicationJob
  queue_as :scraped_data

  def perform(file_url)
    # Dont run these jobs anymore
    # return

    auctionhouse = nil
    catalogue = nil
    catalogue_url = nil

    s3 = Aws::S3::Client.new
    resp = s3.get_object(
      bucket: ENV['S3_BUCKET_NAME'],
      key: file_url
    )

    resp = resp.body.read.rstrip.split("\n")
    first_lot = JSON.parse(resp.first, symbolize_names: true)
    auctionhouse = Site.find_by_slug(first_lot[:auctionhouse])
    auctionhouse = Site.find_by(name: first_lot[:auctionhouse].titleize) if auctionhouse == nil

    if auctionhouse == nil
      NotifierService.new(PostToSlackJob).site_not_found(first_lot[:auctionhouse], file_url) if Rails.env.production?
      return
    end

    resp.each do |line|
      lot = JSON.parse(line, symbolize_names: true)

      if catalogue_url == nil || catalogue_url != lot[:catalogue_url]
        catalogue_data = {
          name: lot[:catalogue_name],
          url: lot[:catalogue_url],
          start_date: lot[:catalogue_startdate],
          site_id: auctionhouse.id,
          location: lot[:catalogue_location]
        }
        catalogue = Catalogue.find_or_initialize_by(url: lot[:catalogue_url])
        catalogue.update!(catalogue_data)
        catalogue_url = lot[:catalogue_url]
      end

      last_line = line.equal?(resp.last) ? true : false

      ScraperdataCreateProductJob.perform_later(lot, auctionhouse, catalogue, last_line)
    end
  end


  def cancelled?
    Sidekiq.redis {|c| c.exists("cancelled-#{jid}") }
  end

  def self.cancel!(jid)
    Sidekiq.redis {|c| c.setex("cancelled-#{jid}", 86400, 1) }
  end
end
