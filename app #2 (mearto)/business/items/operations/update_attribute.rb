# frozen_string_literal: true

module Items
  module Operations
    class UpdateAttribute < BaseOperation
      def call
        within_transaction do
          build_form
          return validation_fail unless form_valid?

          assign_attributes
          return validation_fail unless save_record

          success(args)
        end
      end

      private

      def form_class
        Items::Forms::UpdateAttribute
      end
    end
  end
end
