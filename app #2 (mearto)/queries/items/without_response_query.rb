# frozen_string_literal: true

module Items
  class WithoutResponseQuery < BaseQuery
    WITHOUT_RESPONSE_PERIOD = 90.days.ago

    def call
      @collection.joins(mearto_appraisals: :comments).where(table[:created_at].lteq(WITHOUT_RESPONSE_PERIOD))
    end

    private

    def record_class
      Comment
    end
  end
end
