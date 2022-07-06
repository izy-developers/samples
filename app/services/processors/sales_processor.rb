# frozen_string_literal: true

module Processors
  # this class will trigger processing of different sales files
  # and create one batch to allow us to track all sale creation jobs
  # are completed
  class SalesProcessor < BaseSalesAndKonditionsProcessor
    def processed_class
      Sale
    end

    def run
      super do
        process_german_sales
        process_global_revenues
        process_forecasts
        process_budgets
      end
    end

    def process_german_sales
      sal_rev_de_files = if full_import
                           Dir.glob("#{data_path}/sal_rev_de_*")
                         else
                           files = Dir.glob("#{data_path}/sal_rev_de_*").select do |f|
                             year = f.match(/.*\/sal_rev_de_(.*)\.csv/).captures.first.to_i
                             year >= import_from.year
                           end
                           files + ["#{data_path}/sal_rev_de_fromincl2020.csv"]
                         end

      sal_rev_de_files&.each do |file|
        log('process_german_sales', file)
        Processors::Sales::GermanSalesProcessor.new(processor_params(file)).run
      end
    end

    def process_global_revenues
      rev_files = Dir.glob("#{data_path}/rev_global_*_w_customers.csv")
      rev_files.each do |file|
        log('process_global_revenues', file)
        Processors::Sales::GlobalRevenuesProcessor.new(processor_params(file)).run
      end
    end

    def process_forecasts
      rev_files = Dir.glob("#{data_path}/fc*.csv")
      rev_files.each do |file|
        log('process_forecasts', file)
        Processors::Sales::ForecastsProcessor.new(processor_params(file)).run
      end
    end

    def process_budgets
      file = "#{data_path}/BU.csv"
      log('process_budgets', file)
      Processors::Sales::BudgetsProcessor.new(processor_params(file)).run
    end

    def processor_params(file_location)
      {
        file_location: file_location,
        hub_process_id: hub_process_id,
        import_from: import_from,
        pcs_to_import: pcs_to_import
      }
    end
  end
end
