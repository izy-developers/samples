# frozen_string_literal: true

module GoogleOCR
  class RecognizeImage
    OCR_TOKEN = Rails.application.credentials[Rails.env.to_sym][:google_api_key]
    OCR_URL = "https://vision.googleapis.com/v1/images:annotate?key=#{OCR_TOKEN}"
    IMAGE_PRODUCT_FORM_PAGE_ERROR_TITLE = 'ImageProductFormPage error'
    FEATURE_TYPE = 'DOCUMENT_TEXT_DETECTION'
    LANGUAGE_CODE = 'en'
    JSON_TYPE = 'application/json'
    RESPONSES_KEY = 'responses'
    LOGGER_PATH = 'log/recognize_image.log'

    def initialize(image_urls, product)
      @image_urls = image_urls
      @product = product
      @tries_count = 0
    end

    def perform
      @image_urls.each do |page_number, url|
        image_product_form_page = ImageProductFormPage.find_or_create_by(product_id: @product.id,
                                                                         page_number: page_number)
        http_response = try_to_recognize(url)
        error_log(IMAGE_PRODUCT_FORM_PAGE_ERROR_TITLE) unless http_response.response.is_a? Net::HTTPSuccess
        set_raw_data(image_product_form_page, http_response) if http_response.response.is_a? Net::HTTPSuccess
        @tries_count = 0
      end
      ImageProductFormPage.where(product_id: @product.id)
    rescue StandardError => e
      error_log(e)
    end

    private

    def try_to_recognize(url)
      http_response = recognize_image(url)
      status = http_response[RESPONSES_KEY].first.try(:[], 'textAnnotations').try(:first).try(:[],
                                                                                              'description').present?
      return http_response if status
      raise StandardError, 'Retry Regonizing from Google OCR' if @tries_count > 5

      @tries_count += 1
      try_to_recognize(url)
    end

    def set_raw_data(image_product_form_page, http_response)
      raw_data = http_response[RESPONSES_KEY].first.try(:[], 'textAnnotations')
                                             .try(:first).try(:[], 'description')
      image_product_form_page.update(raw_data: raw_data)
    end

    def error_log(e)
      message = "ImageProductFormPage with id=#{@product.id}"
      Logger.new(LOGGER_PATH).error(e.message + message)
    end

    def recognize_image(image_url)
      params = { 'requests': [{
        'image': {
          'source': {
            'imageUri': image_url.to_s
          }
        },
        'features': [
          {
            'type': FEATURE_TYPE
          }
        ],
        'imageContext': {
          'languageHints': [LANGUAGE_CODE]
        }
      }] }
      HTTParty.post(OCR_URL, body: params.to_json, headers: { 'Content-Type': JSON_TYPE })
    end
  end
end
