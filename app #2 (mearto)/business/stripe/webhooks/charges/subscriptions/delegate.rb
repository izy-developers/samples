# frozen_string_literal: true

module Stripe
  module Webhooks
    module Charges
      module Subscriptions
        class Delegate < BaseAction
          CHARGE_SUCCEEDED = 'charge.succeeded'
          CHARGE_FAILED = 'charge.failed'

          def call
            case event.type
            when CHARGE_SUCCEEDED
              Stripe::Webhooks::Charges::Subscriptions::Succeeded.call(event: event)
            when CHARGE_FAILED
              Stripe::Webhooks::Charges::Subscriptions::Failed.call(event: event)
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
