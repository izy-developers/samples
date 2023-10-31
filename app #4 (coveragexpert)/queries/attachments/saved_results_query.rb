# frozen_string_literal: true

module Attachments
  class SavedResultsQuery < BaseQuery
    def form_url
      saved_results_cabinet_dashboard_index_path
    end

    private

    def scope
      Attachment
        .joins(:product)
        .saved_by(current_user)
        .where(product: Product.scoped)
    end
  end
end
