# frozen_string_literal: true

module Stripe
  module Webhooks
    module Charges
      module Offers
        class Failed < BaseAction
          def call
            logger.info 'Offer charges failed'
            # Marketplace::AdminNotificationsMailer.offer_action_failed(event, admin)
          end
        end
      end
    end
  end
end
