# frozen_string_literal: true

class DiscountDeductionDecorator
  include BaseDecorator

  def get_general_summary(from_date = time_now.years_ago(2).beginning_of_year, to_date = time_now, source = 'sales')
    the_response = {}

    sales_data = CacheGen.run(key: "all_sales_data_info", from: from_date, to: to_date, type: source) do
      ProfitCenter.all.get_sales_grouped_by_year_and_month(from_date, to_date, 'euro', false, false, source)
    end

    sales_ytd = CacheGen.run(key: "all_sales_ytd_info", from: beginning_of_year, to: time_now, type: source) do
      source.singularize.capitalize.constantize.valid_between_times(beginning_of_year, time_now).for_euro
    end

    the_response[:sales] = as_info(sales_data, true, nil, source)
    the_response[:countries_sales] = sales_by_country(from_date, to_date, source)
    the_response[:discount_in_invoice] = discount_in_invoice(sales_ytd, source)
    the_response[:sales_deduction] = sales_deduction(sales_ytd)
    the_response[:customer_discounts] = discounts_by_customer(beginning_of_year, time_now)

    the_response
  end

  def get_graph_data(from_date, to_date, the_params)
    object_type = the_params[:object_type]
    source = the_params[:source]
    if %w[countries customers].include?(object_type)
      object = object_type.singularize.classify.constantize.find_by_id(the_params[:id])
      sales = CacheGen.run(key: 'sales_detail_graph_data_info', name: object.name, from: from_date, to: to_date, type: source) do
        case object
        when Country
          country_sales(object, from_date, to_date, source)
        when Customer
          object.get_sales_grouped_by_year_and_month(from_date, to_date, 'euro', false, false, source)
        end
      end
    elsif %w[discounts deductions].include?(object_type)
      sales = CacheGen.run(key: 'sales_detail_graph_data_info', name: the_params[:object_name],
                           type: object_type, from: from_date, to: to_date, param_1: source) do
        case the_params[:condition_type]
        when 'discount_type'
          SaleKondition.effective.where(visible_name: the_params[:object_name]).valid_between_times(from_date, to_date)
        when 'deduction_type'
          sap_id = SALE_DEDUCTION_DEFINITIONS.filter { |a| a[:visible_name] == the_params[:object_name] }.first[:sap_id]
          klass = source == 'sales' ? Sale : Kondition
          klass.valid_between_times(from_date, to_date)
            .includes(:profit_center_variant)
            .where(profit_center_variants: { sap_id: sap_id })
            .for_euro
        end
      end
    end
    dd_grouped_by_year_and_month(sales, object_type, from_date.year, to_date.year, source)
  end

  private

  def sales_by_country(from_date = time_now.years_ago(2).beginning_of_year, to_date = time_now, source = 'sales')
    countries = Country.visible.active.map do |country|
      as_info(country_sales(country, from_date, to_date, source), true, country).merge!(id: country.id, country: country.name)
    end

    countries.sort_by { |h| -(h[:discount_in_invoice] + h[:sales_deductions]) }.reverse!
  end

  def discount_in_invoice(sales, sale_source)
    CacheGen.run(key: 'sales_detail_discount_in_invoice_info', from: beginning_of_year, to: time_now, type: sale_source) do
      month_sales = sales.valid_between_times(time_now - 1.month, time_now)
      month_gross_sales = get_gross_sales_one(month_sales.is_sale)

      SaleKondition.effective.where(salable_id: sales.ids, salable_type: sale_source.singularize.capitalize).group_by(&:visible_name)
        .map do |arr|
          next if arr.first == 'Price'

          month_sale_konditions = arr.second
                                     .select { |sk| !sk.sales_time.nil? && sk.sales_time >= (time_now - 1.month) }
                                     .pluck(:amount).sum.round(2)
          {
            discount_type: arr.first || 'undefined',
            in_EUR_month: month_sale_konditions.round(2),
            in_percent_month: (month_sale_konditions / month_gross_sales * 100).round(2),
            in_EUR_YTD: arr.second
                                    .select { |sk| !sk.sales_time.nil? && sk.sales_time >= beginning_of_year }
                                    .pluck(:amount).sum.round(2)
          }
        end.compact.reject { |h| zero_discounts?(h) }.sort_by { |arr| arr[:in_EUR_YTD] }
    end
  end

  def sales_deduction(sales)
    CacheGen.run(key: 'sales_detail_sales_deductions_info', from: beginning_of_year, to: time_now) do
      sales_deduction_details(sales)
    end
  end

  def discounts_by_customer(from_date = beginning_of_year, to_date = time_now)
    CacheGen.run(key: 'sales_detail_discounts_by_customer_info', from: from_date, to: to_date) do
      customers = Customer.top_discount_customers(from_date, to_date)
      customers.map do |customer|
        sales_ytd = summarize_period_values(
          customer.get_sales_grouped_by_year_and_month(from_date, to_date, 'euro', false, false, 'sales')
                  .aggregated_for_period(from_date, to_date)
        )

        next if sales_ytd.empty?

        sales_gross_two_in_euro = sales_ytd[:sales_gross_two_in_euro] || 0
        sales_discounts_in_euro = sales_ytd[:sales_discounts_in_euro] || 0

        gross_sales_one_ytd = sales_gross_two_in_euro - sales_discounts_in_euro
        discounts_euro_ytd = sales_discounts_in_euro
        discounts_percent_ytd = gross_sales_one_ytd.nonzero? ? (discounts_euro_ytd / gross_sales_one_ytd * 100) : 0

        deductions_euro_ytd = sales_ytd[:sales_deductions_in_euro] || 0
        gross_sales_two_ytd = sales_ytd[:sales_gross_two_in_euro] || 0
        deductions_percent_ytd = gross_sales_two_ytd.nonzero? ? (deductions_euro_ytd / gross_sales_two_ytd * 100) : 0

        share = gross_sales_one_ytd.nonzero? ? ((discounts_euro_ytd + deductions_euro_ytd) / gross_sales_one_ytd * 100) : 0

        {
          id: customer.id,
          customer_name: customer.name,
          discount_in_invoice_YTD: discounts_euro_ytd.round(2),
          discount_in_percent_YTD: discounts_percent_ytd.round(2),
          sales_deductions_YTD: deductions_euro_ytd.round(2),
          sales_deductions_percent_YTD: deductions_percent_ytd.round(2),
          share: share.round(2)
        }
      end.reject { |h| (h[:discount_in_invoice_YTD] + h[:sales_deductions_YTD]).zero? }
         .sort_by { |arr| -arr[:share] }
         .reverse!
    end
  end

  def as_info(sales = nil, with_pricing_summary = false, object = nil, source = 'sales')
    sales_ytd = sales.aggregated_for_period(beginning_of_year, time_now)

    sales_summarized = sales_ytd.values.each_with_object(Hash.new(0)) { |v, h| v.each_key { |k| h[k.to_sym] += v[k] } }

    out = {
      discount_in_invoice: sales_summarized[:"#{source}_discounts_in_euro"].round(2),
      sales_deductions: sales_summarized[:"#{source}_deductions_in_euro"].round(2),
      FC_discount_in_invoice: sales_summarized[:forecast_discounts_in_euro].round(2),
      FC_sales_deductions: sales_summarized[:forecast_deductions_in_euro].round(2),
      BU_discount_in_invoice: sales_summarized[:budget_discounts_in_euro].round(2),
      BU_sales_deductions: sales_summarized[:budget_deductions_in_euro].round(2)
    }

    out.merge!(pricing_summary: pricing_summary(sales)) if with_pricing_summary

    if object
      sales_deductions_list = CacheGen.run(key: "details_sales_deductions_info", from: beginning_of_year, to: time_now,
                                           name: object.name, ids: [object.id], type: source) do
        if source == 'sales'
          sales_deduction_details(object.get_sales)
        else
          sales_deduction_details(object.get_konditions)
        end
      end

      konditions = CacheGen.run(key: "details_sales_discounts_info", from: beginning_of_year, to: time_now,
                                name: object.name, ids: [object.id], type: source) do
        kondition_discounts(object, source)
      end

      out.merge!(sales_deductions_list: sales_deductions_list)
      out.merge!(konditions: konditions)
    end

    out
  end

  def country_sales(country, from_date, to_date, source)
    CacheGen.run(key: 'sales_detail_country_sales_info', name: country.name, from: from_date, to: to_date, type: source) do
      country.get_sales_grouped_by_year_and_month(from_date, to_date, 'euro', false, false, source)
    end
  end

  def get_total_deductions(sales)
    (discounts(sales) + deductions(sales.is_deduction)).round(2)
  end

  def dd_grouped_by_year_and_month(sales, object_type, from_year = time_now.year_ago(1).year, to_year = time_now.year, source = 'sales')
    case object_type
    when 'countries'
      country_details_graph_hash(sales, source)
    when 'customers'
      customer_graph_hash(sales, source)
    else
      (from_year..to_year).each_with_object({}) do |year, h|
        dd_grouped_by_month(sales&.for_year(year), object_type, year).each { |k, v| h[k] = v }
      end.compact
    end
  end

  def dd_grouped_by_month(sales, object_type, prep_year = nil)
    (1..12).each_with_object({}) do |month, h|
      time_key = "#{prep_year}-#{month}"

      sales_for_month = sales&.for_month(prep_year, month)

      case object_type
      when 'deductions'
        out = sale_deductions_graph_hash(sales_for_month.is_sale_deduction)
      when 'discounts'
        out = sale_discounts_graph_hash(sales_for_month)
      end

      h[time_key] = out
    end
  end

  def country_details_graph_hash(sales, source = 'sales')
    sales.each_with_object(DateHash.new) do |(k, v), h|
      h[k] ||= {}
      v.symbolize_keys!
      h[k][:discounts] = v[:"#{source}_discounts_in_euro"] || 0
      h[k][:deductions] = v[:"#{source}_deductions_in_euro"] || 0
      h[k][:net_sales] = v[:"#{source}_in_euro"] || 0
      h[k][:forecast_sales] = v[:forecasts_in_euro] || 0
      h[k][:forecast_discounts] = v[:forecast_discounts_in_euro] || 0
      h[k][:forecast_deductions] = v[:forecast_deductions_in_euro] || 0
    end
  end

  def customer_graph_hash(sales, source = 'sales')
    sales.each_with_object(DateHash.new) do |(k, v), h|
      h[k] ||= {}
      v.symbolize_keys!
      h[k][:discounts] = v[:"#{source}_discounts_in_euro"] || 0
      h[k][:deductions] = v[:"#{source}_deductions_in_euro"] || 0
      h[k][:net_sales] = v[:"#{source}_in_euro"] || 0
    end
  end

  def sale_discounts_graph_hash(sales_for_month)
    {
      discounts: summarize(sales_for_month, :amount)
    }
  end

  def sale_deductions_graph_hash(sales_for_month)
    {
      deductions: summarize(sales_for_month, :amount)
    }
  end
end
