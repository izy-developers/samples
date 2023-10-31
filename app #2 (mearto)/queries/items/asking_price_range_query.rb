module Items
  class AskingPriceRangeQuery < BaseQuery
    def call
      return @collection if params_empty?

      if min_asking_price.positive? && max_asking_price.zero?
        @collection.where(table[:asking_price_cents].gteq(min_asking_price))
      elsif min_asking_price.zero? && max_asking_price.positive?
        @collection.where(table[:asking_price_cents].lteq(max_asking_price))
      else
        @collection.where(asking_price_cents: min_asking_price..max_asking_price)
      end
    end

    private

    def record_class
      Item
    end

    def min_asking_price
      @min_asking_price ||= params[:asking_price_attrs][:min_asking_price].to_i * 100
    end

    def max_asking_price
      @max_asking_price ||= params[:asking_price_attrs][:max_asking_price].to_i * 100
    end

    def params_empty?
      params[:asking_price_attrs][:min_asking_price].blank? && params[:asking_price_attrs][:max_asking_price].blank?
    end
  end
end
