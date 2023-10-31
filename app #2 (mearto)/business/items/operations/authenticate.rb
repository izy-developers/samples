# frozen_string_literal: true

module Items
  module Operations
    class Authenticate < BaseOperation
      AUTHENTICATION_EMAIL = ['authenticate@mearto.com', 'karine.sarant@mearto.com']

      def call
        upload_item_images
        send_notification
        success(args)
      rescue StandardError
        response(:fail, args)
      end

      private

      attr_reader :user, :images, :params

      def upload_item_images
        @images = params[:images].map do |image|
          key = "authenticate/#{SecureRandom.hex}/#{image.original_filename}"
          obj = s3_resource.bucket(ENV['S3_BUCKET_NAME']).object(key)
          obj.upload_file(image.path, acl: 'public-read')
          { filename: image.original_filename, path: obj.public_url }
        end
      end

      def send_notification
        SpecialistMailer.new_art_authenticate_item(AUTHENTICATION_EMAIL, user, contact_params, images).deliver_later
      end

      def s3_resource
        @s3_resource ||= Aws::S3::Resource.new(credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'],
                                                                                 ENV['AWS_SECRET_ACCESS_KEY']),
                                               region: ENV['AWS_REGION'])
      end

      def contact_params
        params.permit(:artist, :dimensions, :materials, :signature, :stamps, :description, :acquired, :provenance)
      end
    end
  end
end
