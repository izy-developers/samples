# frozen_string_literal: true

module Attachments
  class BaseQuery
    include Filters
    include Rails.application.routes.url_helpers

    def initialize(params, current_user)
      @params = params
      @current_user = current_user
    end

    def items
      @items = scope.includes(:attachment_type,
                              product: [:lob_tags, :business_classes, { companies: :company_group }])
                    .ransack(new_params)
      @items.sorts = 'product_id_num asc' if @items.sorts.blank?
      @items.result
    end

    def ransack_object
      scope.ransack(new_params)
    end

    private

    attr_reader :params, :current_user

    def attachments
      @attachments ||= scope.ransack(new_params)
      @attachments.result
    end

    def scope
      raise 'Not Implemented'
    end

    def new_params
      params[:q].try(:merge, m: 'and')
    end
  end
end
