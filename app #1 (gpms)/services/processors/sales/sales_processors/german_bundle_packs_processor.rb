# frozen_string_literal: true

# Will process sales file for German customers
# and schedule jobs to create sales.
module Processors
  module Sales
    module SalesProcessors
      class GermanBundlePacksProcessor < BaseSalesProcessor
        def initialize(options = {})
          super
        end

        def import_row(row)
          sales_time = get_sales_time(row)
          return if !sales_time || sales_time < import_from

          customer_id = find_or_create_customer_id(row)
          add_customer_to_update_list(row, customer_id) if customer_id

          revenues = row[:price].to_f
          num_of_items = row[:num_of_items].to_f

          return if revenues.to_f.zero? && num_of_items.zero?

          # Save a bundle sale for each product
          pcv = ProfitCenterVariant.find_by_sap_id(normalize_int(row[:pcv_sap_id]))
          return if pcv.nil?

          sale_params = [
            'sale',
            pcv.profit_center_id,
            customer_id,
            pcv.id,
            sales_time,
            revenues * num_of_items,
            num_of_items,
            row[:currency] || 'EUR',
            is_deduction?(row),
            row[:customer_group] || nil,
            true
          ]
          sales_array << sale_params

          return unless %w[A B D].include?(row[:type])

          # Save a sale for bundle pack if it's A or B
          bundlepack = ProfitCenterVariant.bundle.find_by_sap_id(normalize_int(row[:bundle_sap_id]))
          return if bundlepack.nil?

          bundle_sales = sales_array.find { |r| r[3] == bundlepack.id && r[4] == sales_time }

          if bundle_sales.present?
            i = sales_array.find_index(bundle_sales)
            sales_array[i][5] += revenues * num_of_items
            sales_array[i][6] = 1
          else
            sale_params = [
              'sale',
              bundlepack.profit_center_id,
              customer_id,
              bundlepack.id,
              sales_time,
              revenues * num_of_items,
              1,
              row[:currency] || 'EUR',
              is_deduction?(row),
              row[:customer_group] || nil,
              true
            ]
            sales_array << sale_params
          end
        end

        private

        def headers_map
          {
            bundle_sap_id: '_MATERIAL',
            pcv_sap_id: '_ZARTKOMP',
            customer_id: '_CUSTOMER',
            valid_from: '_DATEFROM',
            valid_to: '_DATETO',
            type: '_ZBIOAART',
            num_of_items: '_QUANTITY',
            price: '_ZPRICE',
            currency: '_CURRENCY'
          }.freeze
        end

        def csv_options
          { col_sep: ';' }
        end

        def get_sales_time(row)
          return if row[:valid_from].nil?

          Time.zone.parse(row[:valid_from])
        end
      end
    end
  end
end
