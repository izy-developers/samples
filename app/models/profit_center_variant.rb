# == Schema Information
#
# Table name: profit_center_variants
#
#  id                     :bigint           not null, primary key
#  profit_center_id       :bigint
#  product_variant_id     :bigint
#  sap_id                 :string
#  sap_name               :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  status                 :string           default("active")
#  price_info             :json
#  is_visible             :boolean          default(FALSE)
#  pricing_principle_info :json
#  short_name             :string           default("")
#  gpms_name              :string           default("")
#  gpms_id                :string
#  eng_name               :string
#
class ProfitCenterVariant < ApplicationRecord
  include PcvSearchModel #used for search functionality - moved to its own file to remove clutter from main model...
  include DiscountModel
  include StatableData
  include AnalisableData
  include SalesAggregatableData

  self.discount_key = 'profit_center_variant'
  self.analysis_key = 'profit_center_variant'
  self.stat_key = 'profit_center_variant'
  self.multi_currency_sales = true

  #DB & model relations
  belongs_to :product_variant
  belongs_to :profit_center
  has_many :price_buildups
  has_many :sales
  has_many :price_change_requests

  #Hooks
  after_touch :update_or_create_analysis_data
  after_touch :update_price_info
  after_touch :update_pricing_principle_info

  #scopes
  scope :has_active_state,      -> { where(status: 'active' ) }
  scope :is_active,             -> { where(status: ['active', 'planned for launch', 'material in change', 'material expires']) }
  scope :is_visible,            -> { where(status: ['material added w/o product requirement', 'active', 'planned for launch', 'material in change', 'material expires']) }
  scope :visible,               -> { where(is_visible: true ) }
  scope :invisible,             -> { where(is_visible: false ) }
  scope :pc_visible,            -> { where(profit_center: { is_visible: true }) }
  scope :is_deduction,          -> { where(sap_id: 8000000..8999999)}
  scope :not_deduction,         -> { where.not(sap_id: 8000000..8999999)}

  #Constants
  STATE_NUM = {
    '1': 'not defined',
    '2': 'not defined',
    '10': 'material added w/o product requirement',
    '20': 'not defined',
    '30': 'active',
    '40': 'not defined',
    '50': 'planned for launch',
    '60': 'material in change',
    '98': 'material expires',
    '99': 'material deleted',
    '88': 'correction material'
  }

  # We reset elevated fields for now
  ELEVATED_INFO_FIELDS = %w[].freeze

  alias_attribute :name, :sap_name

  #Class Methods
  def self.sap_num_to_gpms_state(num)
    self::STATE_NUM[num.to_s.to_sym] ? self::STATE_NUM[num.to_s.to_sym] : 'not defined'
  end

  def self.get_price_buildups
    PriceBuildup.where profit_center_variant_id: self.pluck(:id).flatten.uniq
  end

  def self.get_countries
    Country.visible.where id: self.find_each.map(&:get_country).flatten.uniq
  end

  def self.to_json
    self.find_each.map(&:to_json)
  end

  def self.get_sales
    Sale.where(profit_center_variant_id: self.pluck(:id))
  end

  def self.get_product_variants
    ProductVariant.where(id: all.pluck(:product_variant_id).uniq)
  end

  def self.get_products
    Product.where(id: self.get_product_variants.map(&:product_id).uniq)
  end

  def self.get_brands
    Brand.where(id: self.get_products.map(&:brand_id).uniq)
  end

  def self.get_pricing_principle_overview
    calc_hash = { 'is_valid' => true }

    self.find_each.map(&:pricing_principle_info).each do |pcv_principles|

      pcv_principles.each do |principle|
        the_name = principle['principle_name']
        the_status = principle['status']

        calc_hash[the_name] = { 'valid' => 0, 'invalid' => 0 } unless calc_hash[the_name].present?

        if the_status
          calc_hash[the_name]['valid'] += 1
        else
          calc_hash['is_valid'] = false
          calc_hash[the_name]['invalid'] += 1
        end
      end
    end

    calc_hash
  end

  def self.pcv_search(the_params)
    limit = the_params[:items_per_page] ? the_params[:items_per_page].to_i : 20
    offset = the_params[:page] ? (the_params[:page].to_i * limit - limit) : (1 * limit - limit)
    info = the_params[:info] ? the_params[:info] : false
    order_by = the_params[:order_by] ? the_params[:order_by] : false

    cache_key = [
        "pcv_search_cont",
        the_params.to_s.gsub(/[\{\"\}\s*]/,'').gsub(',','_').gsub('=>','-').gsub('nil','.').strip,
        limit.to_s,
        offset.to_s,
        info.to_s,
        order_by.to_s
    ].join('___')

    Rails.cache.fetch(cache_key, :expires_in => 24.hours) do
      ProfitCenterVariant.search_by_params(the_params, limit, offset, info, order_by)
    end
  end

  def self.get_avg_margins
    margin_array_this_month = Array.new
    margin_array_last_month = Array.new

    self.includes(:analysis_objects).find_each do |pcv|
      this_month_scope = pcv.analysis_objects.valid_between_times((Time.zone.now - 30.days),(Time.zone.now)).is_monthly.order('valid_from ASC')
      last_month_scope = pcv.analysis_objects.valid_between_times((Time.zone.now - 60.days),(Time.zone.now - 30.days)).is_monthly.order('valid_from ASC')
      this_month_info = this_month_scope.present? ? this_month_scope.first.payload : {}
      last_month_info = last_month_scope.present? ? last_month_scope.first.payload : {}

      if this_month_info.keys.include?('marg_man')
        value = this_month_info['marg_man']
        value = value.nil? || value.nan? || value.infinite? ? nil : value
        margin_array_this_month << value if value.present?
      end

      if last_month_info.keys.include?('marg_man')
        value = last_month_info['marg_man']
        value = value.nil? || value.nan? || value.infinite? ? nil : value
        margin_array_last_month << value if value.present?
      end
    end

    last_month = margin_array_last_month.empty? ? 0.0 : margin_array_last_month.flatten.mean.round(2)
    this_month = margin_array_this_month.empty? ? 0.0 : margin_array_this_month.flatten.mean.round(2)

    {
      this_month: this_month,
      last_month: last_month
    }

  rescue
    {
      this_month: 0.0,
      last_month: 0.0
    }
  end

  def self.price_buildup_level_type(short_name, value)
    if short_name == 'other'
      value.is_a?(Numeric) ? 'number' : 'text'
    else
      PriceBuildupSchema.get_field_type(short_name)
    end
  end

  def self.currency_deviations(day = Time.zone.now)
    corrected_day = day.beginning_of_month

    keys = %w[curr_dev c_loss r_loss c_loss_loc r_loss_loc]
    value_arrs = keys.map { |k| [k, []] }.to_h
    local_currency = all.first&.get_list_price_currency&.short_name || 'Local Curr'

    AnalysisObject.where(statable: all, data_type: 'monthly', valid_from: corrected_day).each do |obj|
      payload = obj.payload
      keys.each do |key|
        val = payload[key]
        next if val.nil? || (val.is_a?(Float) && val.nan?) || val.infinite?
        value_arrs[key] << val.to_f
      end
    end

    out = {}
    value_arrs.each do |key, arr|
      out[key] = (key == 'curr_dev') ? arr.mean : arr.inject(:+).to_f
    end

    format_currency_deviations(out, local_currency)
  end

  def self.format_currency_deviations(data, local_currency)
    data.each_with_object([]) do |(k, v), a|
      a << {
        full_name: PriceBuildupSchema.get_full_name(k).gsub('Local Curr', local_currency),
        short_name: k,
        value: v,
        type: 'currency'
      }
    end
  end

  # group should be an array or scope of pcvs with the same sap_id
  def self.correct_pcv_for_group(group)
    return nil if group.empty?

    return group.first if group.size == 1

    visible_pcvs = group.select { |pcv| pcv.is_visible }
    return visible_pcvs.first if visible_pcvs.size > 0

    group.first
  end

  def self.correct_pcv_by_sap_id(sap_id)
    group = where(sap_id: sap_id)
    correct_pcv_for_group(group)
  end

  #Instance Methods

  def short_name
    self.read_attribute(:short_name).present? ? self.read_attribute(:short_name) : self.sap_name[0..3]
  end

  def gpms_name
    db_name = self.read_attribute(:gpms_name)

    if db_name.present?
      self.read_attribute(:gpms_name)
    else
      [
        self.get_brand.name,
        (self.get_product.name unless self.get_product.short_name == '#'),
        self.product_variant.variant_name,
        self.get_country.iso_code
      ].join(' ').squish
    end
  end

  def calculate_price_info(the_day=Time.zone.now, item_type='monthly')
    if item_type == 'daily'
      the_day = the_day.beginning_of_day
      correct_buildup = self.price_buildups.valid_for_day(the_day.to_s).correct_buildup
      correct_buildup.present? ? correct_buildup.calculate_price_buildup(the_day) : {}
    elsif item_type == 'monthly'
      the_day = the_day.beginning_of_month
      correct_buildup = self.price_buildups.valid_for_day(the_day.to_s).correct_buildup
      correct_buildup.present? ? correct_buildup.calculate_price_buildup(the_day) : {}
    else
      puts "Not supported yet"
      false
    end
  end

  def calculate_and_process_price_info(day)
    raw_buildup = calculate_price_info(day)
    return [{}, {}, {}] unless raw_buildup

    price_info_payload = raw_price_info_to_payload(raw_buildup)
    PriceBuildupChecker.new(price_info: price_info_payload).run
    additional_data = AdditionalPriceInfoService.new(self, price_info_payload, day, 'monthly').calculate

    [raw_buildup, price_info_payload, additional_data]
  end

  def store_price_info_range_to_analytics(cur_valid_from, cur_valid_until, verbose = false)
    max_valid_to = Time.zone.now.end_of_year + YEARS_TO_IMPORT_FORWARD

    val_from, val_to = [cur_valid_from, cur_valid_until].sort

    val_from = VALID_MIN_FROM if val_from < VALID_MIN_FROM
    val_to = max_valid_to if val_to > max_valid_to

    val_from = val_from.beginning_of_month
    val_to = val_to.beginning_of_month

    current_time_gap = val_from
    while current_time_gap <= val_to
      puts "sap_id=#{sap_id} store buildup analysis for #{current_time_gap.to_date}" if verbose
      store_buildup_to_analysis_for_day(current_time_gap)
      current_time_gap += 1.month
    end
  end

  #todo: add some logic based on field type...
  def store_as_value_type(field_name, value)
    #returning this for now
    value.is_a?(Array) ? value.first : value
  end

  #override of the default get_stat_data_item in statable_data - using the country stat data for additional fallback
  def get_stat_data_item(key, day=Time.zone.now, item_type='monthly', fallback = true)
    return get_stat(key, day, item_type) unless fallback

    # passing arguments to the super method, but adding an additional block for queries
    # block is using arguments that are getting passed in the super method if the block exists
    super(key, day, item_type) do |corrected_day, item_type_lvl|
      get_stat(key, corrected_day, item_type_lvl)
    end
  end

  def get_graph_data(time_from, time_to, data_resolution='monthly', elevated=true, verbose=false, real_data=false)
    graph_keys = [
      'cogs',
      'marg_man',
      'lp1',
      'lp2',
      'ws_pprice_net',
      'ph_pprice_net',
      'ret_price_incl_vat'
    ]

    graph_keys = graph_keys.map { |key| key = "#{key}_stat" } if real_data

    graph_keys = graph_keys - ELEVATED_INFO_FIELDS unless elevated

    get_analysis_graph_data(graph_keys, time_from, time_to, data_resolution, 2, true, verbose)
  end

  # available exch_conversion types: local, fixed, actual
  def get_analysis_detail_graph_data(key, time_from, time_to, data_resolution='monthly', exch_conversion=nil, round_to=2, fix_margin=false, verbose=false)
    return {} unless key.is_a?(String)

    corresponding_stat_key = PriceBuildupSchema.get_corresponding_stat_field(key)

    if exch_conversion.present? && PriceBuildupSchema.valid_additional_info_field?(key)
      currency = self.get_list_price_currency

      unless currency.is_main
        key = PriceBuildupSchema.convert_to_extension_field(key, exch_conversion)
        corresponding_stat_key = PriceBuildupSchema.convert_to_extension_field(corresponding_stat_key, exch_conversion)
      end
    end

    graph_keys = [key, corresponding_stat_key]

    get_analysis_graph_data(graph_keys, time_from, time_to, data_resolution, round_to, fix_margin, verbose)
  end

  def get_analysis_graph_data(key_or_keys, time_from, time_to, data_resolution='monthly', round_to=2, fix_margin=false, verbose=false)
    graph_keys = key_or_keys.is_a?(String) ? [key_or_keys] : key_or_keys
    raw_data = self.analysis_objects.get_time_frame_data(graph_keys, data_resolution, time_from, time_to, verbose)
    clean_analysis_detail_graph_data(get_in_percent(raw_data), round_to, fix_margin)
  end

  def get_in_percent(raw_data)
    raw_data_keys = raw_data.keys
    raw_data_keys.each do |key|
      item_keys = raw_data[key.to_s].keys
      item_keys.each do |item_key|
        next if raw_data[key.to_s][item_key.to_s].nil?
        field_type = PriceBuildupSchema.get_field_type(item_key)
        raw_data[key.to_s][item_key.to_s] = raw_data[key.to_s][item_key.to_s] * 100  if field_type == 'percent'
      end
    end

    raw_data
  end

  def clean_analysis_detail_graph_data(raw_data, round_to=2, fix_margin=false)
    output_data = Hash.new

    if round_to && round_to.is_a?(Integer)
      raw_data.each do |k, v|
        output_data[k] = {}

        v.each do |key, val|
          lp1 = key.include?('_stat') ? v['lp1_stat'] : v['lp1']
          val = (lp1 * val) / 100 if val && fix_margin && key.include?('marg_') && lp1
          output_data[k][PriceBuildupSchema.get_full_name(key)] = val.to_f.round(round_to)
        end
      end
    else
      output_data = raw_data
    end

    output_data
  end

  #/analysis stuff

  def get_or_create_price_info
    if !self.price_info.present? || self.price_info.empty?
      if self.touch
        self.price_info
      end
    else
      self.price_info
    end
  end

  def price_info
    JSON.parse(self[:price_info]) || self[:price_info]
  rescue
    self[:price_info]
  end

  def raw_price_info_to_payload(raw_price_info)
    raw_price_info.inject({}) do |acc, h|
      key = h[0]
      val = h[1]
      val = val.is_a?(Hash) ? val[:value] : val
      value_to_store = store_as_value_type(key, val)
      acc[key] = value_to_store

      acc
    end
  end

  def get_price_info(date = Time.zone.now)
    currency = self.get_list_price_currency
    currency_short = currency.short_name

    out = { 'Currency' => currency.name, 'Currency Short' => currency_short }
    raw_price_info, _price_info_payload, additional_data = calculate_and_process_price_info(date)

    raw_price_info.each do |key, val|
      value = get_value_as_type(key, val[:value])
      out[val[:full_name]] = value
    end
    additional_data.each do |lvl_name, value|
      if !currency.is_main && PriceBuildupSchema.is_extension_field?(lvl_name)
        parsed_data = PriceBuildupSchema.parse_extension_field(lvl_name, true)

        case parsed_data
        in { field_name: full_name, conversion_type: 'eur' }
          out['eur'] ||= {}
          out['eur'][full_name] = value&.round(2)
        in { field_name: full_name, conversion_type: 'local' }
          out['loc_cur'] ||= {}
          out['loc_cur'][full_name] = value&.round(2)
        else
          #nothing
        end
      elsif PriceBuildupSchema.is_price_dev_field?(lvl_name)
        parsed_data = PriceBuildupSchema.parse_price_dev_field(lvl_name, true)

        if parsed_data[:conversion_type] == 'value'
          out['value_dev'] ||= Hash.new
          out['value_dev'][parsed_data[:field_name]] = -value.round(2)
        end
      elsif PriceBuildupSchema.is_deviation_field?(lvl_name)
        full_name = PriceBuildupSchema.get_full_deviation_name(lvl_name)
        out[full_name] = lvl_name == 'curr_dev' ? -value.round(2) : value.round(2)
      end
    end

    sales_scope = self.get_sales.is_sale.for_euro.valid_between_times(Time.zone.now.beginning_of_month, Time.zone.now)
    unless sales_scope.present?
      out['List price gross II real'] = 0.0
    end

    out.transform_keys(&:to_s)
  end

  # available currency types: loc_cur, eur
  def get_price_info_in_currency(currency_type = 'loc_cur', elevated = true, date = Time.zone.now)
    currency = get_list_price_currency
    the_price_info = self.get_price_info(date)

    return format_price_buildup_info(the_price_info, elevated) if currency.is_main

    output_price_info = {}
    converted_hash = the_price_info[currency_type]

    return if converted_hash.blank?

    the_price_info.each do |full_name, val|
      output_price_info[full_name] = converted_hash[full_name] || val
    end

    unless currency_type == 'loc_cur'
      output_price_info['Currency'] = 'Euro'
      output_price_info['Currency Short'] = 'EUR'
    end

    format_price_buildup_info(output_price_info, elevated)
  end

  def get_value_as_type(field_name, value)
    return value if value.nil?

    field_type = PriceBuildupSchema.get_field_type(field_name)
    output_val = field_type == 'percent' ? value * 100.0 : value

    output_val.is_a?(Numeric) ? output_val.round(2) : output_val
  end

  def get_or_create_pricing_principle_info
    if !self.pricing_principle_info.present? || self.pricing_principle_info.empty?
      if self.touch
        self.pricing_principle_info
      end
    else
      self.pricing_principle_info
    end
  end

  def get_pricing_principle_info
    PricingPrinciples::Checker.new(self).run
  end

  def pricing_principle_info
    JSON.parse(self[:pricing_principle_info]) || self[:pricing_principle_info]
  rescue
    self[:pricing_principle_info]
  end

  def get_sales
    @sales ||= self.sales
  end

  def get_price_buildups
    @price_buildups ||= self.price_buildups
  end

  def to_sap_status_num
    self.class::STATE_NUM.key(self.status) ? self.class::STATE_NUM.key(self.status).to_s.to_i : 1
  end

  def get_product_variant
    @pv ||= self.product_variant
  end

  def get_product
    @product ||= self.get_product_variant.product
  end

  def get_brand
    @brand ||= self.get_product&.brand
  end

  def get_manufacturer
    @manufacturer ||= self.get_brand&.manufacturer
  end

  def get_pv_countries
    @pv_countries ||= self.product_variant.get_countries
  end

  def get_country
    @country ||= get_profit_center.get_country || Country.find_by_iso_code('DE')
  end

  def get_countries
    @countries = self.get_profit_center.countries.visible
  end

  def get_currency
    @currency ||= self.get_country.get_currency
  end

  def get_profit_center
    @profit_center ||= self.profit_center
  end

  def to_info(more_info=false, is_elevated=false)
    cache_key = [
        "profit_center_variant_to_info",
        self.id.to_s,
        more_info.to_s,
        is_elevated.to_s
    ].join('___')

    Rails.cache.fetch(cache_key, :expires_in => 24.hours) do
      {
        id: self.id,
        sap_id: self.sap_id,
        sap_name: self.sap_name,
        gpms_name: self.gpms_name,
        status: self.status,
        product_variant: self.get_product_variant.as_info(true),
        product: self.get_product&.as_info(true),
        brand: self.get_brand&.to_info,
        manufacturer: self.get_manufacturer&.to_info,
        country: self.get_country&.to_info(more_info),
        price_info: extended_price_info(is_elevated),
        pricing_principle_info: self.get_or_create_pricing_principle_info,
        eng_name: self.eng_name
      }
    end
  end

  # TODO: move somewhere else
  def decorator_info(more_info=true)
    out = {
      id: self.id,
      sap_id: self.sap_id,
      sap_name: self.sap_name,
      eng_name: self.eng_name,
      gpms_name: self.gpms_name,
      status: self.status,
      is_visible: self.is_visible
    }

    out.merge!(
      product_variant: self.get_product_variant.as_info(true),
      product: self.get_product ? self.get_product.as_info(true) : nil,
      brand: self.get_brand ? self.get_brand.to_info : nil
    ) if more_info

    out
  end

  # def to_json # TODO: Fix this back up to be able to use it on show
  #   self.as_info(true).to_json
  # end

  def as_info(limited = false, is_elevated = false)
    out = to_info(
      !limited,
      is_elevated
    ).merge({
      product_variant_id: get_product_variant.id,
      product_id: get_product&.id,
      brand_id: get_brand&.id,
      manufacturer_id: get_manufacturer&.id,
      country_id: get_country.id
    })

    unless limited
      out = out.merge({
        available_currencies: get_switch_currencies,
        currency_id: get_currency.id,
        currency_name: get_currency.name,
        currency_short: get_currency.short_name
      })
    end

    out
  end

  def extended_price_info(elevated = true)
    info = get_or_create_price_info || {}

    format_price_buildup_info(info, elevated)
  end

  def format_price_buildup_info(info, elevated)
    out = info.map do |k, v|
      short_name = PriceBuildupSchema.get_short_name(k)
      {
        short_name: short_name,
        full_name: k,
        type: self.class.price_buildup_level_type(short_name, v),
        value: v
      }
    end

    elevated ? out : out.reject { |i| ELEVATED_INFO_FIELDS.include?(i[:short_name]) }
  end

  def get_switch_currencies
    [get_list_price_currency&.short_name, Currency.get_main_currency.short_name].compact.uniq
  end

  # TODO: check if used - potentially outdated method
  def get_list_price(maxprice=true, condition_name=nil)
    if self.price_buildups.present? && self.price_buildups.is_valid.present?
      range = self.price_buildups.is_valid.real_vtweg.get_list_price_range(condition_name)
      out = maxprice ? range.last : range.first
      out ? out : 0.0
    else
      0.0
    end
  end

  # TODO: check if used - potentially outdated method
  def get_cogs_price
    if self.price_buildups.present? && self.price_buildups.is_valid.present?
      out = self.price_buildups.get_cogs_price
      out ? out : 0.0
    else
      0.0
    end
  end

  def get_list_price_currency(time_at = Time.zone.now)
    @correct_buildups ||= price_buildups.correct_buildup(false).to_a
    correct_buildup = @correct_buildups.find { |b| b.valid_from <= time_at && b.valid_until >= time_at }

    if correct_buildup.present?
      return correct_buildup.currency
    end

    Currency.get_main_currency
  end

  # TODO: check if used - potentially outdated method
  def create_default_price_buildup
    self.price_buildups.create_default_price_buildup
  end

  def create_or_update_price_buildup(
    valid_from, valid_until, currency_short, pricing_condition_name,
    pricing_vtweg, pricing_pltype, auart, schema_iso
  )
    currency = Currency.get_pricing_currency(currency_short.upcase)

    price_buildup_scope = price_buildups
                            .condition_scope(pricing_condition_name, pricing_vtweg, pricing_pltype, auart)
                            .with_currency_id(currency.id)

    existing_price_buildup = price_buildup_scope.where(valid_from: valid_from, valid_until: valid_until).last
    if existing_price_buildup.present?
      existing_price_buildup.update(price_buildup_schema_name: "price_buildup_schema_#{schema_iso}") if schema_iso
      return
    end

    price_buildup_scope.overlaps(valid_from, valid_until).destroy_all

    price_buildup_name = "pb_#{pricing_condition_name.downcase}_#{pricing_vtweg}_#{pricing_pltype}_#{auart.downcase}"
    params = {
      name: price_buildup_name,
      currency_id: currency.id,
      valid_from: valid_from,
      valid_until: valid_until
    }
    params = params.merge(price_buildup_schema_name: "price_buildup_schema_#{schema_iso}") if schema_iso
    price_buildup = price_buildups.create(params)
    price_buildup.set_active_state

    condition = PricingCondition.where(
      name: pricing_condition_name, pl_type: pricing_pltype, vt_weg: pricing_vtweg, au_art: auart
    ).first_or_create do |pc|
      pc.name = pricing_condition_name
      pc.vt_weg = pricing_vtweg
      pc.pl_type = pricing_pltype
      pc.au_art = auart
    end
    price_buildup.pricing_conditions << condition
  end

  def store_buildup_to_analysis_for_day(day = Time.zone.now)
    _raw_buildup, price_info_payload, additional_data = calculate_and_process_price_info(day)

    full_payload = price_info_payload.merge(additional_data)
    analysis_objects.create_or_update_multi(full_payload, 'monthly', day)
  end

  def get_currencies_graph(type, data_resolution, from_date, to_date)
    if type != 'price'
      [
        self.get_country.get_currency.short_name,
        self.get_currency.get_graph_data(Time.zone.parse(from_date.to_s), Time.zone.parse(to_date.to_s), data_resolution)
      ]
    else
      correct_buildup = self.get_price_buildups.valid_between_times(Time.zone.parse(from_date.to_s), Time.zone.parse(to_date.to_s)).correct_buildup
      [
        correct_buildup.currency.short_name,
        correct_buildup.currency.get_graph_data(Time.zone.parse(from_date.to_s), Time.zone.parse(to_date.to_s), data_resolution)
      ]
    end
  end

  def has_analysis_data_for_day?(day=Time.zone.now, item_type='monthly')
    corrected_day = correct_day_per_item_type(item_type, day)
    analysis_data_scope = self.analysis_objects.get_data_scope(corrected_day, item_type)
    analysis_data_scope.present? && analysis_data_scope.first.has_key?('cogs')
  end

  # use this method to generate analysis test data for a specific pcv to avoid running full analysis data import
  def generate_test_analysis_data(
    from_time = (Time.zone.now-1.year).beginning_of_year,
    to_time = (Time.zone.now + 3.months),
    verbose = true
  )
    store_price_info_range_to_analytics(from_time, to_time, verbose)
  end

  def create_price_buildup_copy
    day = Time.zone.now
    pb = price_buildups.valid_for_day(day.to_s).correct_buildup
    return unless pb

    pb.copy
  end

  def create_price_change_request
    day = Time.zone.now
    pb = price_buildups.valid_for_day(day.to_s).correct_buildup
    return unless pb

    PriceChangeRequest.create_from_price_buildup(pb)
  end

  def get_stat_without_country_fallback(key, day = Time.zone.now, item_type = 'monthly')
    stat_objects.get_value_for_time_and_key(key, day, item_type)
  end

  def get_price_buildup_value_euro(key, date)
    euro_key = get_list_price_currency.is_main ? key : "#{key}_eur"
    analysis_objects.get_value_for_time_and_key(euro_key, date, 'monthly')
  end

  private

  def get_stat(key, day, item_type_lvl)
    pcv_stat = stat_objects.get_value_for_time_and_key(key, day, item_type_lvl)
    return pcv_stat if pcv_stat

    get_country.stat_objects.get_value_for_time_and_key(key, day, item_type_lvl)
  end

  def update_or_create_analysis_data
    store_buildup_to_analysis_for_day if !has_analysis_data_for_day? && price_buildups.any?
  end

  def update_price_info
    self.price_buildups.find_each.map &:touch
    self.update_column :price_info, self.get_price_info.to_json
  end

  def update_pricing_principle_info
    update_column(:pricing_principle_info, get_pricing_principle_info.to_json)
  end
end
