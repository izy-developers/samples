# frozen_string_literal: true

# Will process forecasts file and schedule jobs to create sales.
module Processors
  module Sales
    module SalesProcessors
      class ConsigneeSalesProcessor < BaseSalesProcessor
        attr_accessor :not_found_customers, :not_found_sales

        def initialize(options = {})
          self.not_found_customers = []
          self.not_found_sales = []
          super
        end

        def headers_map
          {
            pc_sap_id: 'pc_key',
            customer_external_id: 'customerid',
            consignee_external_id: 'WarenempfängerID',
            consignee_name: 'Warenempfängername',
            pcv_sap_id: 'material_key',
            year: 'year',
            month: 'month',
            revenues: 'revenues',
            currency: 'cur',
            num_of_items: 'sales',
            unit: 'unit',
            customer_group: 'CustGrp',
            customer_group_two: 'CustGrp2',
            customer_name: 'customername'
          }.freeze
        end

        def import_row(row)
          return unless consignee_prioritized?(row)
          return if sample_pcv?(row)

          customer = find_customer(row[:customer_external_id].to_s.strip)
          consignee = find_customer(row[:consignee_external_id].to_s.strip)

          return unless consignee

          return if landcur? && row[:currency] == 'EUR'

          pc_id = find_profit_center_id(row)
          return unless pc_id
          return unless import_pc?(pc_id)

          sales_time = get_sales_time(row)
          pcv_id = find_pcv_id(row, sales_time)
          return if pcv_id.blank?

          pcv = ProfitCenterVariant.find(pcv_id)
          currency = find_currency(row[:currency])
          return if currency.blank?

          sale = nil
          ProfitCenterVariant.where(sap_id: pcv.sap_id).each do |product|
            sale = find_sale(customer, sales_time, product, currency, row[:revenues].to_f)

            break if sale
          end

          return unless sale

          sale.update!(customer_id: consignee.id)
        end

        def after_import; end

        def landcur?
          file_location.include?('landcur')
        end
      end
    end
  end
end
