# frozen_string_literal: true

module Processors
  module Sales
    # will process global revenues file and schedule jobs to create sales
    class GlobalRevenuesProcessor < BaseSalesProcessor
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
          customer_name:'customername'
        }.freeze
      end

      def import_row(row)
        row[:num_of_items] = 0 if row[:unit].to_s.downcase == 'kg'
        return if landcur? && row[:currency] == 'EUR'

        super
      end

      def landcur?
        file_location.include?('landcur')
      end
    end
  end
end
