# frozen_string_literal: true

module Buyers
  class SortingQuery < BaseQuery
    # Accepts only user collection from the AdminUsersQuery

    def call
      return @collection unless sort_option_valid?

      @collection.order("#{sort_option} desc")
    end

    private

    def record_class
      Buyer
    end

    def sort_option
      params[:sort_option]
    end

    def sort_option_valid?
      %w[messages_count offers_count accepted_offers_count paid_out_offers_count].include?(sort_option)
    end
  end
end
