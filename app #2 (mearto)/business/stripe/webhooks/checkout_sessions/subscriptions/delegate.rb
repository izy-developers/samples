# frozen_string_literal: true

module Stripe
  module Webhooks
    module CheckoutSessions
      module Subscriptions
        class Delegate < BaseAction
          SESSION_COMPLETED = 'checkout.session.completed'

          def call
            case event.type
            when SESSION_COMPLETED
              handle_completed_session
            else
              event_not_handling
            end
          end

          private

          attr_reader :event

          def handle_completed_session
            Stripe::Webhooks::CheckoutSessions::Subscriptions::Completed.call(event: event)
          end
        end
      end
    end
  end
end
