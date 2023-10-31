require 'benchmark'
class ScraperdataCreateProductJob < ApplicationJob
  queue_as :scraped_data

  def perform(lot, site, catalogue, last_line)
    auctionhouse = site
    currency = nil
    product = nil
    products_to_index = nil

    Benchmark.bm(20) do |bm|  # The 20 is the width of the first column in the output.
      lot[:catalogue_url] = lot[:catalogue_url].split('?')[0]
      lot[:url] = lot[:url].gsub('http', 'https') unless lot[:url].include?('https')

      bm.report("Find Site:") {
        if auctionhouse == nil || auctionhouse.slug != lot[:auctionhouse]
          auctionhouse = Site.find_by_slug(lot[:auctionhouse])
          if auctionhouse == nil
            auctionhouse = Site.find_by(name: lot[:auctionhouse].titleize)
          end
        end
      }

      bm.report("Find Currency:") {
        currency = Currency.find_by_name(lot[:currency].upcase)
      }

      bm.report("Find Product:") {
        product = Product.find_or_initialize_by(url: lot[:url])
        product.update!(
           url: lot[:url],
           valuation_from: lot[:estimate_min],
           valuation_to: lot[:estimate_max],
           sold_for: lot[:sold_for],
           expire_at: lot[:date],
           title: lot[:title],
           description: lot[:description],
           currency: currency,
           # location_id: '',
           site: auctionhouse,
           catalogue: catalogue,
           artist_name: lot[:artist_name],
           dimensions: lot[:dimensions],
           provenance: lot[:provenance],
           condition: lot[:condition],
           indexing_after_scraping: false,
           no_reindex: true
        )
      }

      bm.report("Clear Images:") {
        product.images.clear
      }

      bm.report("Insert Images:") {
        images = []
        lot[:images][0,2].each do |i|
          images << {path: i[:url], path_s3: i[:path], file_hash: i[:checksum]}
        end
        product.images.create(images)
      }

      bm.report("Index 200:") {
        products_to_index = Product.where(site_id: auctionhouse.id, indexing_after_scraping: false)
        if last_line || products_to_index.count >= 200
          products_to_index.update_all(indexing_after_scraping: true)
          Product.bulk_index_slicing(products_to_index)
          puts last_line ? '-------- Indexing The Rest -----------' : '-------- Indexing 200 -----------'
        end
      }
    end
  end
end
