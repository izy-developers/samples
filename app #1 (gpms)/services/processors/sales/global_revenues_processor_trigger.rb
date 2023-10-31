# frozen_string_literal: true

# Will trigger processing of different sales files.
module Processors
  module Sales
    class GlobalRevenuesProcessorTrigger < BaseSalesProcessorTrigger
      def processed_class
        Sale.where.not(profit_center_id: Country.find_by(name: 'Germany').get_profit_centers.ids).general_sales
      end

      def run
        super do
          process_global_revenues
        end
      end

      def process_global_revenues
        rev_files = Dir.glob("#{data_path}/rev_global_*_w_customers.csv")
        rev_files.each do |file|
          log('process_global_revenues', file)
          Processors::Sales::SalesProcessors::GlobalRevenuesProcessor.new(processor_params(file)).run
        end
      end

      class Cleaner < GlobalRevenuesProcessorTrigger
        def run
          cleanup_sales
        end
      end
    end
  end
end
