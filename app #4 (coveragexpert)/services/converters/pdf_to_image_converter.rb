# frozen_string_literal: true

module Converters
  class PdfToImageConverter
    def self.convert_pdf_to_images(directory_manager, file_name, _options)
      @images_info = {}

      pdf = MiniMagick::Image.open(directory_manager.tmp_dir.join(file_name))
      pdf.pages.each_with_index do |page, index|
        converted_image = page.format(:png, index, density: 300)
        converted_image.combine_options do |img|
          img.alpha :remove
          img.quality 100
          img.threshold '60%'
        end
        img_path = directory_manager.images_dir.join("#{index}.png")
        converted_image.write(img_path)
        @images_info[index.to_s] = img_path
      end
      @images_info
    end
  end
end
