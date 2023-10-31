# frozen_string_literal: true

module Stripe
  module Webhooks
    module CheckoutSessions
      module Offers
        class Completed < BaseAction
          def call
            logger.info 'Offer checkout session completed'
          end

          private

          attr_reader :event
        end
      end
    end
  end
end
