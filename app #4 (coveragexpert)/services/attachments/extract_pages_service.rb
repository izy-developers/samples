# frozen_string_literal: true

module Attachments
  class ExtractPagesService
    def initialize(attachment, only_preview)
      @attachment = attachment
      @only_preview = only_preview || true
    end

    def self.call_async(attachment, only_preview)
      ExtractPagesWorker.perform_async(attachment.id, only_preview) unless attachment.attachment_pages.any?
    end

    def call
      attachment.attachment_pages.destroy_all

      if only_preview
        convert_preview
      else
        convert_pages
      end
    end

    private

    attr_reader :attachment, :only_preview

    def convert_page(page, index)
      converted_image = page.format(:jpg, index, density: 300)
      converted_image.combine_options do |img|
        img.alpha :remove
        img.quality 100
        img.resize '300x350>'
      end

      create_attachment(converted_image, index)
    end

    def convert_pages
      pdf.pages.each_with_index do |page, index|
        convert_page(page, index)
      end
    end

    def convert_preview
      convert_page(pdf.pages.first, 0)
    end

    def create_attachment(converted_image, index)
      attachment.attachment_pages.create!(
        page_number: index,
        file_name: converted_image,
        file_width: converted_image.width,
        file_height: converted_image.height
      )
    end

    def pdf
      MiniMagick::Image.open(file_url)
    end

    def file_url
      @attachment.file_name.url
    end
  end
end
