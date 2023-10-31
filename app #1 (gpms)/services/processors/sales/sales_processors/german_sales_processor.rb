# frozen_string_literal: true

# Will process sales file for German customers
# and schedule jobs to create sales.
module Processors
  module Sales
    module SalesProcessors
      class GermanSalesProcessor < BaseSalesProcessor
        def headers_map
          {
            pc_sap_id: 'pc_key',
            customer_external_id: 'customerid',
            pcv_sap_id: 'material_key',
            consignee_name: 'Warenempfängername',
            year: 'year',
            month: 'month',
            revenues: 'revenues',
            num_of_items: 'sales',
            customer_group: 'CustGrp',
            customer_group_two: 'CustGrp2',
            customer_name: 'customername'
          }.freeze
        end
      end
    end
  end
end
