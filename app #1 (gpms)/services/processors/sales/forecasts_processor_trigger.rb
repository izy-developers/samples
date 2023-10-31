# frozen_string_literal: true

# Will trigger processing of different sales files.
module Processors
  module Sales
    class ForecastsProcessorTrigger < BaseSalesProcessorTrigger
      def processed_class
        Sale.general_forecast
      end

      def run
        super do
          process_forecasts
        end
      end

      def process_forecasts
        rev_files = Dir.glob("#{data_path}/fc*.csv")
        rev_files.each do |file|
          log('process_forecasts', file)
          Processors::Sales::SalesProcessors::ForecastsProcessor.new(processor_params(file)).run
        end
      end

      class Cleaner < ForecastsProcessorTrigger
        def run
          cleanup_sales
        end
      end
    end
  end
end
