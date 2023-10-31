# frozen_string_literal: true

module Stripe
  module Webhooks
    module Charges
      class Delegate < BaseAction
        def call
          case event.data.object.metadata['session_type']
          when 'marketplace_offer'
            Stripe::Webhooks::Charges::Offers::Delegate.call(event: event)
          else
            Stripe::Webhooks::Charges::Subscriptions::Delegate.call(event: event)
          end
        end

        private

        attr_reader :event
      end
    end
  end
end
