# frozen_string_literal: true

# Will process budgets file and schedule jobs to create sales.
module Processors
  module Sales
    module SalesProcessors
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

        def import_row(row)
          pcv_sap_id = row[:pcv_sap_id].to_s.strip

          # we need to skip BU sales for this pcv for 2017 and 2018 because they are zero
          # and we will import BU for 16985 instead. See Task#1035 for details
          return if pcv_sap_id == '13065' && in_2017_or_2018?(row)

          super
        end

        private

        def in_2017_or_2018?(row)
          get_sales_time(row).between?(Time.zone.parse('2017-01-01'), Time.zone.parse('2018-01-01').end_of_year)
        end
      end
    end
  end
end
