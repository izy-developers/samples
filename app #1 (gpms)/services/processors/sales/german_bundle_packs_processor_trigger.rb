# frozen_string_literal: true

# Will trigger processing of different sales files.
module Processors
  module Sales
    class GermanBundlePacksProcessorTrigger < BaseSalesProcessorTrigger
      def processed_class
        Country.find_by(name: 'Germany').get_sales.general_sales.bundle
      end

      def run
        super do
          process_german_bundle_packs
        end
      end

      def process_german_bundle_packs
        sal_rev_de_files = Dir.glob("#{data_path}/aufsteller_aufteilung*")

        sal_rev_de_files&.each do |file|
          log('process_german_bundle_packs', file)
          Processors::Sales::SalesProcessors::GermanBundlePacksProcessor.new(processor_params(file)).run
        end
      end

      class Cleaner < GermanBundlePacksProcessorTrigger
        def run
          cleanup_sales
        end
      end
    end
  end
end
