# frozen_string_literal: true

# Will process cycle through global revenue sale files
# and update sale customers to consignees.
#
# TODO: check if it is still necessary
module Processors
  module Sales
    class ConsigneeProcessorTrigger < BaseSalesAndKonditionsProcessor
      def run
        super do
          consignee_sales
        end
      end

      def before_import; end
      def after_import; end

      def consignee_sales
        rev_files = Dir.glob("#{data_path}/rev_global_*_w_customers.csv")
        rev_files.each do |file|
          log('process_consignee_sales', file)
          Processors::Sales::SalesProcessors::ConsigneeSalesProcessor.new(processor_params(file)).run
        end
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
end
