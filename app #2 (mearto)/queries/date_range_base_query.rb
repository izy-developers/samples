class DateRangeBaseQuery < BaseQuery
  def call
    return @collection if params_empty?

    if min_date.present? && max_date.blank?
      @collection.where(table[params[:field]].gteq(min_date))
    elsif min_date.blank? && max_date.present?
      @collection.where(table[params[:field]].lteq(max_date))
    else
      @collection.where(table[params[:field]].between(min_date.beginning_of_day..max_date.end_of_day))
    end
  end

  private

  def min_date
    return if params[:date_attrs][:min_date].blank?

    @min_date ||= Date.parse(params[:date_attrs][:min_date])
  end

  def max_date
    return if params[:date_attrs][:max_date].blank?

    @max_date ||= Date.parse(params[:date_attrs][:max_date])
  end

  def params_empty?
    params[:date_attrs][:min_date].blank? && params[:date_attrs][:max_date].blank?
  end
end
