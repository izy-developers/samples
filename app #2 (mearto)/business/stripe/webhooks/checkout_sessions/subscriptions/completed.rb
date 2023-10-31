# frozen_string_literal: true

module Stripe
  module Webhooks
    module CheckoutSessions
      module Subscriptions
        class Completed < BaseAction
          def call
            retrieve_stripe_customer
            send_notification if customer.email.present?
          end

          private

          attr_reader :event, :customer

          def retrieve_stripe_customer
            @customer = ::Stripe::Customer.retrieve(event.data.object.customer)
          end

          def send_notification
            logger.info 'Sending email to admin about new paid listing subscription'
            MessageMailer.notify_paid_listing_subscription(customer.email).deliver_later
          end
        end
      end
    end
  end
end
