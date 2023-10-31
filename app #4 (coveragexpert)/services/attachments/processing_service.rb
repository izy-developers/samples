# frozen_string_literal: true

module Attachments
  class ProcessingService
    def initialize(attachment_id, product_id)
      @attachment = Attachment.find(attachment_id)
      @product = Product.find(product_id)
      @attachment_event_service = Attachments::EventService.new(attachment_id)
    end

    def perform
      @attachment_event_service.in_progress_status
      Parsers::PdfParser.new(file_path, file_name, @product, attachment: @attachment).parse
      @attachment_event_service.succeed_status
    rescue StandardError
      @attachment_event_service.failed_status
    end

    private

    def file_path
      @attachment.file_name.path
    end

    def file_name
      @attachment.file_name.file.filename
    end
  end
end
