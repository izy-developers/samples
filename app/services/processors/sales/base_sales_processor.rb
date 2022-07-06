# frozen_string_literal: true

module Processors
  module Sales
    # base class to process different types of sale files
    # and schedule sale creation jobs for them
    class BaseSalesProcessor < BaseSalesAndKonditionsProcessor
      attr_accessor :sales_array, :profit_centers_map, :customer_ids_cache, :pcv_map,
                    :sales_type, :import_from, :sample_ids,
                    :pcs_to_import, :valid_consignee_countries,
                    :exchange_rates_file_path, :exchange_rates, :profit_centers_file_name,
                    :profit_centers_currencies, :all_customer_ids, :customers_map

      def initialize(options = {})
        # may be redefined in descendants
        self.sales_type = 'sale'
        self.pcs_to_import = options[:pcs_to_import] || []
        super
        self.exchange_rates_file_path = "#{data_path}/fixed_exchange_rates_historic.xlsx"
        self.exchange_rates = []

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
        self.sample_ids = load_sample_ids

        get_valid_consignee_pc_ids
      end

      def exchange_rates_file_headers_map
        {
          iso_code: 'iso_code',
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
          deduction?(row),
          row[:customer_group] || nil
        ]

        if %w[budget forecast].include?(sales_type)
          sale_params_in_local_currency = fc_bu_in_local_currency_params(sale_params)

          sales_array << sale_params_in_local_currency if sale_params_in_local_currency
        end

        sales_array << sale_params
      end

      def after_import
        update_customers_groups

        file_name = get_file_name(file_location)
        launch_processor_jobs(sales_array, JobImplementator, file_name)
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

        customer_id = find_customer_id(row, ext_id) || create_customer(row, ext_id)

        customer_ids_cache[ext_id] = customer_id if customer_ids_cache[ext_id].blank?
        log('customer_not_found', customer_id) if customer_id.blank?

        customer_id
      end

      def find_customer_id(row, ext_id)
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

      def deduction?(row)
        (8_000_000..8_999_999).include?(row[:pcv_sap_id].to_i) ||
          (row[:consignee_name].to_s.strip == 'Nicht zugeordnet' && row[:pcv_sap_id].to_s.strip == '#')
      end

      def bulk_sap_id?(row)
        (3_000_000..5_000_000).include?(row[:pcv_sap_id].to_i)
      end

      def load_sample_ids
        headers = {
          sap_id: 'MATNR'
        }
        file = "#{data_path}/Samples_to_be_excluded_sales.csv"

        map_file_with_fallback(file, headers).map { |h| h[:sap_id].to_i }.uniq
      end

      def sample_pcv?(row)
        sample_ids.include?(row[:pcv_sap_id].to_i)
      end

      def import_pc?(pc_id)
        return true if !pcs_to_import || pcs_to_import.empty?

        pcs_to_import.include?(pc_id)
      end

      def get_profit_center_currencies
        ProfitCenter.all.each_with_object({}) do |pc, h|
          local_currency_name = pc.countries
                                  .map(&:get_switch_currencies)
                                  .flatten.uniq
                                  .reject { |v| %w[euro eur].include?(v.downcase) }
                                  .first
          h[pc.id] = { currency: local_currency_name, iso_codes: pc.countries.pluck(:iso_code) } if local_currency_name
        end
      end

      def fc_bu_in_local_currency_params(params)
        pc = profit_centers_currencies[params[1]]
        return unless pc

        currency = pc[:currency]

        valid_month = sales_type == 'budget' ? 1 : params[4].month

        exchange_rate = exchange_rates.filter do |rates|
          pc[:iso_codes].include?(rates[:iso_code]) &&
            rates[:currency] == currency &&
            rates[:month] == valid_month &&
            rates[:year] == params[4].year
        end.first
        return unless exchange_rate

        converted_revenues = params[5] * exchange_rate[:exchange_rate].to_f

        result = params.dup
        result[5] = converted_revenues
        result[7] = currency
        result
      end

      def add_customer_to_update_list(row, customer_id)
        return unless all_customer_ids.include?(customer_id)

        visible = [1, 2, 3, 4, 6, 7, 9, 11, 13, 14, 16, 17, 23].include?(row[:customer_group].to_i) ? true : false

        customers_map[customer_id] ||= {
          customer_group_two: row[:customer_group_two] == '#' ? nil : row[:customer_group_two],
          customer_group: row[:customer_group] == '#' ? nil : row[:customer_group].to_i,
          is_visible: visible
        }
      end

      def update_customers_groups
        customers_map.each do |k, v|
          Customer.find(k).update(v)
        end
      end
    end
  end
end
