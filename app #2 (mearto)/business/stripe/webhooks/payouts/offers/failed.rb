# frozen_string_literal: true

module Stripe
  module Webhooks
    module Payouts
      module Offers
        class Failed < BaseAction
          def call
            logger.info 'Offer Payouts failed: ' + event.data.object.id
            # Marketplace::AdminNotificationsMailer.offer_action_failed(event, admin)
          end
        end
      end
    end
  end
end
