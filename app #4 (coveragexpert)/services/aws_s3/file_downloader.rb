# frozen_string_literal: true

module AwsS3
  class FileDownloader
    attr_reader :file_name

    REGION_NAME = AwsS3::Constants::REGION_NAME
    BUCKET_NAME = AwsS3::Constants::BUCKET_NAME

    def initialize(file_url, file_name, normalized_pdf_path, bucket_name = BUCKET_NAME)
      @s3_client = init_s3_client
      @file_url = file_url
      @file_name = file_name
      @normalized_pdf_path = normalized_pdf_path
      @bucket_name = bucket_name
    end

    def perform
      download_file
      self
    end

    private

    def init_s3_client
      Aws::S3::Client.new(
        region: REGION_NAME,
        access_key_id: Rails.application.credentials[Rails.env.to_sym][:aws][:s3][:access_key_id],
        secret_access_key: Rails.application.credentials[Rails.env.to_sym][:aws][:s3][:secret_access_key]
      )
    end

    def download_file
      resp = @s3_client.get_object(bucket: @bucket_name, key: @file_url)
      body = resp.body.read
      File.open(Rails.root.join('tmp', @normalized_pdf_path, @file_name), 'wb') do |file|
        file.write(body)
      end
    end
  end
end
