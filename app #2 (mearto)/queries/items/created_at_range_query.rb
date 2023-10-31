# frozen_string_literal: true

module Items
  class CreatedAtRangeQuery < DateRangeBaseQuery
    private

    def record_class
      Item
    end
  end
end
