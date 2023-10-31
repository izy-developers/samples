# frozen_string_literal: true

module AwsS3
  class PdfImagesUploader
    attr_reader :file_name

    REGION_NAME = AwsS3::Constants::REGION_NAME
    BUCKET_NAME = AwsS3::Constants::BUCKET_NAME
    EXPIRES_IN_SECONDS = 86_400

    def initialize(images_info, record_id)
      @s3_client = init_s3_client
      @images_info = images_info
      @record_id = record_id
    end

    def perform
      @image_urls = {}
      @images_info.each do |page_number, path_from|
        obj = @s3_client.bucket(BUCKET_NAME)
                        .object("external uploaded temp image files/#{@record_id}/#{page_number}.png")
        obj.upload_file(path_from)
        @image_urls[page_number] = obj.presigned_url(:get, expires_in: EXPIRES_IN_SECONDS)
      end
      @image_urls
    end

    private

    def init_s3_client
      Aws::S3::Resource.new(
        region: REGION_NAME,
        access_key_id: Rails.application.credentials[Rails.env.to_sym][:aws][:s3][:access_key_id],
        secret_access_key: Rails.application.credentials[Rails.env.to_sym][:aws][:s3][:secret_access_key]
      )
    end
  end
end
