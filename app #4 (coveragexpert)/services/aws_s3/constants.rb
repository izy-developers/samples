# frozen_string_literal: true

module AwsS3
  class Constants
    REGION_NAME = 'us-east-2'
    BUCKET_NAME = Rails.env.production? ? 'parsing-entity-production' : 'parsing-entity'
  end
end
