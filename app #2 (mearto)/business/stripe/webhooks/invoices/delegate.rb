# frozen_string_literal: true

module Stripe
  module Webhooks
    module Invoices
      class Delegate < BaseAction
        # Delete the webhook event to an appropriate handler
        def call
          case event.type
          when 'invoice.payment_succeeded'
            Stripe::Webhooks::Invoices::PaymentSucceeded.call(event: event)
          else
            event_not_handling
          end
        end

        private

        attr_reader :event
      end
    end
  end
end
