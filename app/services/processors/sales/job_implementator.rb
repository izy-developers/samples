# frozen_string_literal: true

module Processors
  module Sales
    class JobImplementator < BaseSalesProcessor
      def initialize(options = {})
        @bundle = options[:bundle]
        super
      end

      def run
        @bundle.each do |row|
          type, pc_id, customer_id, pcv_id, sales_time, revenues, num_of_items, currency_short, is_deduction, customer_group = row

          currency = Currency.get_pricing_currency(currency_short)

          sale_params = {
            profit_center_id: pc_id,
            profit_center_variant_id: pcv_id,
            sales_time: sales_time,
            sales_type: is_deduction ? "#{type}_deduction" : type,
            currency_id: currency.id,
            customer_id: customer_id,
            is_average: true,
            billing_period: sales_time,
            status: 'done',
            num_of_items: num_of_items.to_i,
            amount: revenues.to_f,
            customer_group: customer_group.to_i
          }

          Sale.create(sale_params)
        end
      rescue => e
        log('sales_import_error', e)
      end
    end
  end
end
