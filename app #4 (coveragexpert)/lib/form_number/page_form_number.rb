# frozen_string_literal: true

module FormNumber
  class PageFormNumber
    def initialize(page_content)
      @page_content = page_content
    end

    def extract
      normalized_form_number
    end

    private

    def extracted_form_number
      FormNumber::PATTERNS.map do |_company, pattern|
        form_number_text_block.match(pattern).try(:[], 0)
      end.compact.try(:first)
    end

    def form_number_text_block
      @page_content.split("\n").last(5).join("\n")
    end

    def normalized_form_number
      extracted_form_number
        .try(:strip)
        .try(:tr, 'O', '0')
        .try(:tr, "\n", '')
    end
  end
end
