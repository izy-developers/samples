module Helpers
  def send_keys_with_delay(field, keys, delay=0.1)
    keys.each_char do |key|
      sleep delay
      find_field(field).send_keys(key)
    end
  end

  def send_key_with_delay(field, key, delay=0.1)
    sleep delay
    find(field).send_keys(key)
  end

  def screenshot_and_upload_to_s3
    path = save_screenshot(nil, full: true)
    s3 = Aws::S3::Client.new
    resp = s3.put_object(
      bucket: ENV['S3_BUCKET_NAME'],
      key: "capybara/#{path.split('/').last}",
      body: IO.read(path)
    )
  end

  # def get_ebay_item_data(id)
  #   EbayRequest::Shopping.new.response("GetSingleItem", ItemID: id).data["Item"]
  # end
end
