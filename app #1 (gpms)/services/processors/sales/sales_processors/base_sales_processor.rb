# frozen_string_literal: true

# Base class to process different types of sale files
# and schedule sale creation jobs for them.
module Processors
  module Sales
    module SalesProcessors
      class BaseSalesProcessor < BaseSalesAndKonditionsProcessor
        attr_accessor :sales_array, :profit_centers_map, :customer_ids_cache, :pcv_map,
                      :sales_type, :import_from, :sample_ids,
                      :valid_consignee_countries,
                      :exchange_rates_file_path, :profit_centers_file_name,
                      :profit_centers_currencies, :all_customer_ids, :customers_map,
                      :exchange_rate_missing_notifications

        def initialize(options = {})
          # may be redefined in descendants
          self.sales_type = 'sale'
          super
          self.exchange_rates_file_path = "#{data_path}/fixed_exchange_rates_historic.xlsx"
          self.exchange_rate_missing_notifications = {}

          self.all_customer_ids = Customer.ids
          self.customers_map = {}
        end

        private

        def before_import
          self.sales_array = []
          self.profit_centers_map = ProfitCenter.all.map { |pc| [pc.sap_id, pc.id] }.to_h
          self.profit_centers_currencies = get_profit_center_currencies
          pcvs = ProfitCenterVariant.all.group_by(&:sap_id).values.map do |group|
            ProfitCenterVariant.correct_pcv_for_group(group)
          end
          self.pcv_map = pcvs.each_with_object({}) do |pcv, obj|
            obj[pcv.sap_id] = pcv.id
          end
          self.customer_ids_cache = {}
          self.sample_ids = load_sample_ids unless self.class.name.demodulize == 'GermanBundlePacksProcessor'
          get_valid_consignee_pc_ids unless self.class.name.demodulize == 'GermanBundlePacksProcessor'
        end

        def exchange_rates_file_headers_map
          {
            month: 'month',
            year: 'year',
            exchange_rate: 'exchange_rate',
            currency: 'currency'
          }.freeze
        end

        def import_row(row)
          return if sample_pcv?(row)

          pc_id = find_profit_center_id(row)
          return unless pc_id
          return unless import_pc?(pc_id)

          sales_time = get_sales_time(row)
          return if !sales_time || sales_time < import_from

          customer_id = find_or_create_customer_id(row)
          add_customer_to_update_list(row, customer_id) if customer_id

          pcv_id = find_pcv_id(row, sales_time)

          revenues = german_sep_number_to_float(row[:revenues])
          num_of_items = german_sep_number_to_float(row[:num_of_items]).to_i

          return if revenues.to_f.zero? && num_of_items.zero?

          num_of_items = 0 if bulk_sap_id?(row)

          sale_params = [
            sales_type,
            pc_id,
            customer_id,
            pcv_id,
            sales_time,
            revenues,
            num_of_items,
            row[:currency] || 'EUR',
            is_deduction?(row),
            row[:customer_group] || nil
          ]

          if sales_type == 'forecast' || (sales_type == 'budget' && sales_time >= Time.zone.parse('2019-01-01'))
            sale_params_in_local_currency = fc_bu_in_local_currency_params(sale_params)

            sales_array << sale_params_in_local_currency if sale_params_in_local_currency
          end

          sales_array << sale_params
        end

        def after_import
          update_customers_groups unless self.class.name.demodulize == 'GermanBundlePacksProcessor'

          file_name = get_file_name(file_location)
          launch_processor_jobs(sales_array, JobImplementator, file_name)

          notify_about_missing_exchange_rates if exchange_rate_missing_notifications.any?
        end

        # faster alternative to
        # pc_id = ProfitCenter.find_by_sap_id(pc_sap_id)&.id
        def find_profit_center_id(row)
          pc_sap_id = row[:pc_sap_id].to_s.strip
          profit_centers_map[pc_sap_id]
          # log('profit_center_not_found', pc_sap_id) unless pc_id
        end

        # faster alternative to
        # customer_id = Customer.find_by_external_id(row[:customer_external_id].to_s.strip)&.id
        def find_or_create_customer_id(row)
          ext_id =
            consignee_prioritized?(row) ? row[:consignee_external_id].to_s.strip : row[:customer_external_id].to_s.strip

          customer_id = find_customer_id(ext_id) || create_customer(row, ext_id)

          customer_ids_cache[ext_id] = customer_id if customer_ids_cache[ext_id].blank?
          log('customer_not_found', customer_id) if customer_id.blank?

          customer_id
        end

        def find_customer_id(ext_id)
          customer_ids_cache[ext_id] || Customer.find_by_external_id(ext_id)&.id
        end

        def create_customer(row, ext_id)
          return if ext_id.to_i == 0

          Customer.create(name: row[:customer_name].strip, external_id: ext_id).id
        end

        # faster alternative to
        # pcv_id = ProfitCenterVariant.where(sap_id: row[:pcv_sap_id].to_s.strip, profit_center_id: row[pc_sap_id])
        def find_pcv_id(row, sales_time)
          pcv_sap_id = row[:pcv_sap_id].to_s.strip
          pc_sap_id = row[:pc_sap_id].to_s.strip

          # 16985 was used to combine 16547 and 13065 from 2016 to 2020
          # See Task#1035 for details
          if pcv_sap_id == '16985' && from_2016_to_2020?(sales_time)
            case pc_sap_id
            when '1000/107150'
              pcv_sap_id = '16547'
            when '1000/107200'
              pcv_sap_id = '13065'
            end
          # we need to combine 2 pcvs into one
          elsif pcv_sap_id == '16314'
            pcv_sap_id = '17376'
          end

          # log('pcv_not_found', pcv_sap_id) unless pcv_id

          pcv_map[pcv_sap_id]
        end

        def from_2016_to_2020?(sales_time)
          sales_time.between?(Time.zone.parse('2016-01-01'), Time.zone.parse('2020-01-01').end_of_year)
        end

        # may be redefined in descendants
        def month(row)
          row[:month].to_i
        end

        def get_sales_time(row)
          Time.zone.parse("#{row[:year]}-#{month(row)}-1").beginning_of_month
        end

        def is_deduction?(row)
          ProfitCenterVariant.deduction_id?(row[:pcv_sap_id]) ||
            (row[:consignee_name].to_s.strip == 'Nicht zugeordnet' && row[:pcv_sap_id].to_s.strip == '#')
        end

        def bulk_sap_id?(row)
          (3_000_000..5_000_000).include?(row[:pcv_sap_id].to_i)
        end

        def get_profit_center_currencies
          ProfitCenter.all.each_with_object({}) do |pc, h|
            local_currency_name = pc.countries
                                    .map(&:get_switch_currencies)
                                    .flatten.uniq
                                    .reject { |v| %w[euro eur].include?(v.downcase) }
                                    .first
            h[pc.id] = { currency: local_currency_name } if local_currency_name
          end
        end

        def pcv_lp2
          @pcv_lp2 ||=
            ProfitCenterVariant.limit(100).not_deduction
                              .includes(:analysis_objects)
                              .where(analysis_objects: { data_type: 'monthly' })
                              .each_with_object({}) do |pcv, h|
              pcv.analysis_objects.each do |analysis|
                h[pcv.id] ||= {}
                h[pcv.id][analysis.valid_from] = analysis.payload['lp2']
              end
            end
        end

        def fc_bu_in_local_currency_params(params)
          pc = profit_centers_currencies[params[1]]
          return unless pc

          result = params.dup
          currency = pc[:currency]
          result[7] = currency

          pcv_id = params[3]
          sales_time = params[4]
          num_of_items = params[6]
          lp2 = lp2_value(sales_time, pcv_id)
          if lp2 && lp2 > 0
            result[5] = lp2 * num_of_items
            return result
          end

          valid_month = sales_type == 'budget' ? 1 : sales_time.month
          date = "#{params[4].year}-#{valid_month}"

          exchange_rate = nil
          exchange_rate ||= exchange_rates[currency] && exchange_rates[currency][date]

          unless exchange_rate
            add_notification_about_missing_exch_rate(params[1], currency, date)
            return
          end

          converted_revenues = params[5] * exchange_rate

          result[5] = converted_revenues
          result
        end

        # for BU sales we need to lp2 as lp1 * (1 - disc_man)
        # when pcv's lp2 should be overridden by BU_invoice_currency_overview_price_increase.xlsx
        # we use lp1 for end of previous year and disc_man for beginning of this year
        def lp2_value(sales_time, pcv_id)
          time = lp2_month(sales_time, pcv_id)

          if time < sales_time
            pcv = ProfitCenterVariant.find(pcv_id)
            beginning_of_year_obj = pcv.analysis_objects
                                      .where(valid_from: sales_time.beginning_of_year, data_type: 'monthly')
                                      .last&.payload
            disc_man = (beginning_of_year_obj || {})['disc_man'].to_f
            end_of_prev_year_obj = pcv.analysis_objects
                                     .where(valid_from: time, data_type: 'monthly')
                                     .last&.payload
            lp1 = (end_of_prev_year_obj || {})['lp1'].to_f

            lp1 * (1.0 - disc_man)
          else
            pcv_lp2[pcv_id] && pcv_lp2[pcv_id][time]
          end
        end

        def lp2_month(sales_time, pcv_id)
          return sales_time unless sales_type == 'budget'

          valid_from = pcv_valid_from(sales_time, pcv_id)
          sales_time < valid_from ? sales_time.end_of_year.beginning_of_month - 1.year : sales_time
        end

        def pcv_valid_from(sales_time, pcv_id)
          year = sales_time.year

          return bu_local_currency_override[:pcvs][pcv_id][year] if bu_local_currency_override&.dig(:pcvs, pcv_id, year)

          pcv = ProfitCenterVariant.find_by_id(pcv_id)
          return unless pcv

          pcv.get_countries.map(&:iso_code).each do |iso_code|
            if bu_local_currency_override&.dig(:countries, iso_code, year)
              return bu_local_currency_override[:countries][iso_code][year]
            end
          end

          sales_time.beginning_of_year
        end

        def exchange_rates
          @exchange_rates ||=
            map_file_with_fallback(
              exchange_rates_file_path,
              exchange_rates_file_headers_map
            ).each_with_object({}) do |row, result|
              currency = row[:currency].to_s.strip
              date = "#{row[:year]}-#{row[:month]}"

              result[currency] ||= {}
              result[currency][date] ||= row[:exchange_rate].to_f
            end
        end

        def add_notification_about_missing_exch_rate(pc_id, currency, date)
          exchange_rate_missing_notifications[pc_id] ||= {}
          exchange_rate_missing_notifications[pc_id][currency] ||= []
          exchange_rate_missing_notifications[pc_id][currency] << date
        end

        def notify_about_missing_exchange_rates
          exchange_rate_missing_notifications.each do |pc_id, country_hash|
            country_hash.each do |currency, dates|
              pc = ProfitCenter.find(pc_id)
              send_import_notification('fixed_exchange_rate_missing', {
                pc_sap_id: pc.sap_id,
                countries: pc.countries.map(&:iso_code).join(','),
                currency: currency,
                dates: dates.uniq
              })
            end
          end
        end

        def add_customer_to_update_list(row, customer_id)
          return unless all_customer_ids.include?(customer_id)

          visible = [1, 2, 3, 4, 6, 7, 9, 11, 13, 14, 16, 17, 23].include?(row[:customer_group].to_i)

          customers_map[customer_id] ||= {
            customer_group: row[:customer_group] == '#' ? nil : row[:customer_group].to_i,
            customer_group_two: row[:customer_group_two] == '#' ? nil : row[:customer_group_two].to_i,
            is_visible: visible
          }
        end

        def update_customers_groups
          customers_map.each do |k, v|
            Customer.find(k).update(v)
          end
        end

        def bu_local_currency_override_mapping
          {
            year: 'BU_Year',
            country_iso: 'Country',
            valid_from: 'bu_prices_valid_from',
            pcv_sap_id: 'pcv_id'
          }.freeze
        end

        def bu_local_currency_override
          file_path = "#{data_path}/BU_invoice_currency_overview_price_increase.xlsx"

          @bu_local_currency_override ||=
            map_file_with_fallback(
              file_path,
              bu_local_currency_override_mapping
            ).each_with_object({}) do |row, result|
              pcv_sap_id = row[:pcv_sap_id].to_i
              pcv_id = pcv_map[pcv_sap_id]
              country_iso = row[:country_iso].to_s.strip
              raw_valid_from = row[:valid_from].to_s.strip
              year = row[:year].to_i
              valid_from = if raw_valid_from.present?
                             Time.zone.parse(raw_valid_from)
                           else
                             # we set next year to do full override
                             Time.zone.parse("#{year + 1}-01-01")
                           end

              if pcv_id && pcv_id > 0
                result[:pcvs] ||= {}
                result[:pcvs][pcv_id] ||= {}
                result[:pcvs][pcv_id][year] = valid_from
              else
                result[:countries] ||= {}
                result[:countries][country_iso] ||= {}
                result[:countries][country_iso][year] = valid_from
              end
            end
        end
      end
    end
  end
end
