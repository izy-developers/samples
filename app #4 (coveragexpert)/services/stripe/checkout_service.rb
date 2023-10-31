# frozen_string_literal: true

module Stripe
  class CheckoutService
    include Rails.application.routes.url_helpers
    PAYMENT_METHOD_TYPES = ['card'].freeze
    MODE = 'payment'

    class << self
      delegate :url_helpers, to: 'Rails.application.routes'

      def call(user:, amount:, type:, attachment_id: nil)
        Stripe::Checkout::Session.create(
          {
            payment_method_types: PAYMENT_METHOD_TYPES,
            line_items: line_items(amount),
            mode: MODE,
            success_url: success_url(type, attachment_id),
            cancel_url: error_url(type, attachment_id),
            customer_email: user.email
          }
        )
      end

      private

      def line_items(amount)
        [{
          price_data: {
            currency: 'usd',
            product_data: {
              name: 'Top up balance'
            },
            unit_amount: (amount * 100).to_i
          },
          quantity: 1
        }]
      end

      def success_url(type, attachment_id)
        case type
        when 'top_up_and_purchase'
          url_helpers.purchase_completed_cabinet_balance_index_url(id: attachment_id)
        when 'top_up'
          url_helpers.top_up_completed_cabinet_balance_index_url
        end
      end

      def error_url(type, attachment_id)
        case type
        when 'top_up_and_purchase'
          url_helpers.purchase_error_cabinet_balance_index_url(id: attachment_id)
        when 'top_up'
          url_helpers.top_up_canceled_cabinet_balance_index_url
        end
      end
    end
  end
end
