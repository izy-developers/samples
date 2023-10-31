# frozen_string_literal: true

# Will trigger processing of different sales files.
module Processors
  module Sales
    class BudgetsProcessorTrigger < BaseSalesProcessorTrigger
      def processed_class
        Sale.general_budget
      end

      def run
        super do
          process_budgets
        end
      end

      def process_budgets
        file = "#{data_path}/BU.csv"
        log('process_budgets', file)
        Processors::Sales::SalesProcessors::BudgetsProcessor.new(processor_params(file)).run
      end

      class Cleaner < BudgetsProcessorTrigger
        def run
          cleanup_sales
        end
      end
    end
  end
end
