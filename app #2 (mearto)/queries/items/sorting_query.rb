module Items
  class SortingQuery < BaseQuery
    # TODO: split this ordering into separate queries later.
    def call
      case sort_option.to_s
      when /^created_at_/
        @collection.order("items.created_at #{direction}")
      when /^estimate_min_/
        @collection.left_outer_joins(:mearto_appraisals).order("appraisals.estimate_min_cents #{direction} NULLS LAST")
      when /^for_marketplace_/
        @collection.order_by_appraisal(direction)
      else
        raise(ArgumentError, "Invalid sort option: #{sort_option.inspect}")
      end
    end

    private

    def record_class
      Item
    end

    def sort_option
      params[:sort_option]
    end

    def direction
      @direction ||= /desc$/.match?(sort_option) ? 'desc' : 'asc'
    end
  end
end
