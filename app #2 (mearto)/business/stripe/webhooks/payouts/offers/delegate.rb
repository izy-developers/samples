# frozen_string_literal: true

module Stripe
  module Webhooks
    module Payouts
      module Offers
        class Delegate < BaseAction
          PAYOUT_PAID = 'payout.paid'
          PAYOUT_FAILED = 'payout.failed'

          def call
            case event.type
            when PAYOUT_PAID
              Stripe::Webhooks::Payouts::Offers::Paid.call(event: event)
            when PAYOUT_FAILED
              Stripe::Webhooks::Payouts::Offers::Failed.call(event: event)
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
end
