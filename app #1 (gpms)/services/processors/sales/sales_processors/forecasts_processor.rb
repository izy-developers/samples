# frozen_string_literal: true

# Will process forecasts file and schedule jobs to create sales.
module Processors
  module Sales
    module SalesProcessors
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

        def import_row(row)
          sales_time = get_sales_time(row)
          file_name = file_location.split('/').last
          # Checks that current month and later sales are taken from FC.csv only
          return if sales_time >= current_month && file_name != 'fc.csv'

          # Check that we don't use fc.csv for previous months
          return if sales_time < current_month && file_name == 'fc.csv'

          super
        end

        def month(row)
          Date.local_abr_month_to_number(row[:month], :de)
        end
      end
    end
  end
end
