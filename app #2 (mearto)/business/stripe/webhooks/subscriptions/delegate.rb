module Stripe
  module Webhooks
    module Subscriptions
      class Delegate < BaseAction
        def call
          case event.type
          when 'customer.subscription.created'
            Stripe::Webhooks::Subscriptions::Created.call(event: event)
          when 'customer.subscription.deleted'
            Stripe::Webhooks::Subscriptions::Deleted.call(event: event)
          when 'customer.subscription.updated'
            Stripe::Webhooks::Subscriptions::Updated.call(event: event)
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
