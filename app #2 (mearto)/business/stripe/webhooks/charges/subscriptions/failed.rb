# frozen_string_literal: true

module Stripe
  module Webhooks
    module Charges
      module Subscriptions
        # An error occurred during payment with the card. Log the incident
        # test card 4000000000000101
        class Failed < BaseAction
          def call
            # TODO: this is assuming a sub per customer. If the customer has updated the credit card there might be more subscriptions?
            if charge.customer && !charge.customer.empty?
              fetch_subscription
              return if subscription.blank?

              update_subscription
              send_notification
            else
              logger.warn "CHARGE_FAILED: Customer does not exist for event: #{event.id}"
            end
          end

          private

          attr_reader :event, :subscription

          def charge
            @charge ||= event.data.object
          end

          def fetch_subscription
            @subscription = ::Subscription.find_by(stripe_customer_id: charge.customer)
          end

          def update_subscription
            subscription.failed_at = DateTime.current
            subscription.save
          end

          def send_notification
            # TODO: for the future the `failure_code` could be nice to have in the admin
            # if charge.failure_code == 'expired_card'
            #   MessageMailer.subscription_failed_card_expired_email(subscription.seller, subscription).deliver_later
            # else
            #   MessageMailer.subscription_failed(subscription.seller, subscription).deliver_later
            # end
            NotifierService.new(PostToSlackJob).subscription_failed(subscription) unless Rails.env.development?
          end
        end
      end
    end
  end
end
