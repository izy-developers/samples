# frozen_string_literal: true

module Items
  module Forms
    class UpdateAttribute < BaseForm
      PERMITTED_ATTRIBUTES = %i[category_id top_category_id sub_category_id artist_id reason_for_appraisal].freeze
      REQUIRED_ATTRIBUTES = %i[].freeze
      attr_accessor(*PERMITTED_ATTRIBUTES, :record)
    end
  end
end
