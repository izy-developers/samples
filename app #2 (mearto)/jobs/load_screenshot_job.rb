class LoadScreenshotJob < ApplicationJob
  queue_as :default

  def perform(url, id, uuid)
    path = "#{Rails.root}/tmp/#{id}.png"

    ws = Webshot::Screenshot.instance
    file = ws.capture( url, path, width: 1024, height: 800)

    s3 = Aws::S3::Resource.new(
      region: ENV['AWS_REGION'],
      credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
    )

    key = "ebay_sreenshot/#{id}-#{SecureRandom.hex}.png"
    obj = s3.bucket(ENV['S3_BUCKET_NAME']).object(key)
    obj.put(body: File.open(path), acl: 'public-read')

    ActionCable.server.broadcast(
      "screenshot_channel_#{uuid}", { url: obj.public_url }
    )
  end
end
