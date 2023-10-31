# frozen_string_literal: true

module Stripe
  module Webhooks
    module Invoices
      # We've received a payment for an invoice of a subscription
      # so we store this info for future ref and email the customer with an invoice
      # The following callbacks are before the payment has been processed.
      # https://stripe.com/docs/subscriptions/lifecycle
      # Remark if you need to make changes to the invoice before payment
      # there is about that after 'invoice.created'.
      # Webhooks
      # 'invoice.created'
      # 'charge.succeeded'
      class PaymentSucceeded < BaseAction
        def call
          logger.info 'SUBSCRIPTION PAYMENT SUCCESS'
          subscription

          if subscription.present?
            update_subscription
          else
            log_subscription_not_found
          end
        end

        private

        attr_reader :event

        def subscription
          @subscription ||= ::Subscription.find_by(stripe_subscription_id: first_line.id)
        end

        def first_line
          @first_line ||= event.data.object.lines.data.first
        end

        def update_subscription
          subscription.paid_till = Time.at(first_line.period.end).to_datetime
          subscription.subscription_expires_at = Time.at(first_line.period.end).to_datetime
          # Active could have have set to false if first payment fails, but second goes through
          # subscription.active = true
          subscription.save
        end

        def log_subscription_not_found
          logger.warn 'Invoice not found and not marked as paid: ' + first_line.id + ' investigate in Stripe!'
        end
      end
    end
  end
end
