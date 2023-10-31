# frozen_string_literal: true

module Stripe
  module Webhooks
    module Charges
      module Offers
        class Delegate < BaseAction
          CHARGE_SUCCEEDED = 'charge.succeeded'
          CHARGE_FAILED = 'charge.failed'
          CHARGE_REFUNDED = 'charge.refunded'

          def call
            case event.type
            when CHARGE_SUCCEEDED
              Stripe::Webhooks::Charges::Offers::Succeeded.call(event: event)
            when CHARGE_FAILED
              Stripe::Webhooks::Charges::Offers::Failed.call(event: event)
            when CHARGE_REFUNDED
              Stripe::Webhooks::Charges::Offers::Refunded.call(event: event)
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
