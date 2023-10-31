# frozen_string_literal: true

# Will trigger processing of different sales files.
module Processors
  module Sales
    class GermanSalesProcessorTrigger < BaseSalesProcessorTrigger
      def processed_class
        Country.find_by(name: 'Germany').get_sales.general_sales
      end

      def run
        super do
          process_german_sales
        end
      end

      def process_german_sales
        sal_rev_de_files = if full_import
                             Dir.glob("#{data_path}/sal_rev_de_*")
                           else
                             result = german_files_from_year(import_from.year)
                             # for cases where sales for current year are in file for previous year
                             result = german_files_from_year(import_from.year - 1) if result.empty?
                             result
                           end

        sal_rev_de_files&.each do |file|
          log('process_german_sales', file)
          Processors::Sales::SalesProcessors::GermanSalesProcessor.new(processor_params(file)).run
        end
      end

      def german_files_from_year(from_year)
        Dir.glob("#{data_path}/sal_rev_de_*").select do |f|
          year = f.match(/.*\/sal_rev_de_(?:fromincl)?(.*)\.csv/).captures.first.to_i
          year >= from_year
        end
      end

      class Cleaner < GermanSalesProcessorTrigger
        def run
          cleanup_sales
        end
      end
    end
  end
end
