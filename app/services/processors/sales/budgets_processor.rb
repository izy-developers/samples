# frozen_string_literal: true

module Processors
  module Sales
    # will process budgets file and schedule jobs to create sales
    class BudgetsProcessor < BaseSalesProcessor
      def initialize(options = {})
        super
        self.sales_type = 'budget'
      end

      def headers_map
        {
          pc_sap_id: 'pc_key',
          pcv_sap_id: 'material_key',
          year: 'year',
          month: 'month',
          num_of_items: 'sales',
          revenues: 'revenues'
        }.freeze
      end

      def before_import
        self.exchange_rates = map_file_with_fallback(exchange_rates_file_path, exchange_rates_file_headers_map)
        super
      end

      def import_row(row)
        pcv_sap_id = row[:pcv_sap_id].to_s.strip

        # we need to skip BU sales for this pcv for 2017 and 2018 because they are zero
        # and we will import BU for 16985 instead. See Task#1035 for details
        if pcv_sap_id == '13065' && in_2017_or_2018?(row)
          return
        end

        super
      end

      private

      def in_2017_or_2018?(row)
        get_sales_time(row).between?(Time.zone.parse('2017-01-01'), Time.zone.parse('2018-01-01').end_of_year)
      end
    end
  end
end
