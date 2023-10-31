# frozen_string_literal: true

# Will trigger processing of different sales files.
module Processors
  module Sales
    class BaseSalesProcessorTrigger < Processors::BaseSalesAndKonditionsProcessor
      def remove_records
        if full_import
          processed_class.mark_outdated
        else
          scope = processed_class.where("#{processed_class.table_name}.sales_time >= ?", import_from)
          scope = scope.for_pcs(pcs_to_import) if pcs_to_import.any?

          scope.mark_outdated
        end
      end

      def after_import; end

      def cleanup_sales
        if full_import && processed_class.is_relevant.any?
          processed_class.is_outdated.delete_all
        elsif processed_class.where("#{processed_class.table_name}.sales_time >= ?", import_from).is_relevant.any?
          scope = processed_class.is_outdated.where("#{processed_class.table_name}.sales_time >= ?", import_from)
          scope = scope.for_pcs(pcs_to_import).is_outdated if pcs_to_import.any?

          scope.delete_all
        end
      end

      def german_files_from_year(from_year)
        Dir.glob("#{data_path}/sal_rev_de_*").select do |f|
          year = f.match(/.*\/sal_rev_de_(?:fromincl)?(.*)\.csv/).captures.first.to_i
          year >= from_year
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
