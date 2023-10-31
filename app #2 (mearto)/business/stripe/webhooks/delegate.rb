# frozen_string_literal: true

module Stripe
  module Webhooks
    class Delegate < BaseAction
      def call
        handle_webhook do
          case event.type
          when /^customer.subscription/
            Stripe::Webhooks::Subscriptions::Delegate.call(event: event)
          when /^invoice/
            Stripe::Webhooks::Invoices::Delegate.call(event: event)
          when /^charge/
            Stripe::Webhooks::Charges::Delegate.call(event: event)
          when /^checkout.session/
            Stripe::Webhooks::CheckoutSessions::Delegate.call(event: event)
          when /^payout/
            Stripe::Webhooks::Payouts::Delegate.call(event: event)
          else
            event_not_handling
          end
        end
      end

      private

      attr_reader :event
    end
  end
end
