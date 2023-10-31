# frozen_string_literal: true

module Stripe
  module Webhooks
    module Payouts
      class Delegate < BaseAction
        def call
          case event.data.object.metadata['payout_type']
          when 'marketplace_offer'
            Stripe::Webhooks::Payouts::Offers::Delegate.call(event: event)
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
