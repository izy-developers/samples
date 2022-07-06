# frozen_string_literal: true

module Processors
  module Sales
    # will process forecasts file and schedule jobs to create sales
    class ForecastsProcessor < BaseSalesProcessor
      def initialize(options = {})
        super
        self.current_month = Time.zone.now.beginning_of_month
        self.sales_type = 'forecast'
      end

      private

      attr_accessor :current_month

      def headers_map
        {
          pc_sap_id: 'pc_key',
          pcv_sap_id: 'material_key',
          year: 'year',
          month: 'month',
          revenues: 'revenues',
          num_of_items: 'sales'
        }.freeze
      end

      def before_import
        self.exchange_rates = map_file_with_fallback(exchange_rates_file_path, exchange_rates_file_headers_map)
        super
      end

      def import_row(row)
        # Checks that current month and later sales are taken from FC.csv only
        return if get_sales_time(row) >= current_month && file_location.split('/').last != 'fc.csv'

        super
      end

      def month(row)
        Date.local_abr_month_to_number(row[:month], :de)
      end
    end
  end
end
