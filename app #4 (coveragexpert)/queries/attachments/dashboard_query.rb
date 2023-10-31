# frozen_string_literal: true

module Attachments
  class DashboardQuery < BaseQuery
    def form_url
      cabinet_dashboard_index_path
    end

    private

    def scope
      Attachment.joins(:product).merge(Product.scoped)
    end
  end
end
