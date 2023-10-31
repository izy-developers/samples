# frozen_string_literal: true

module Stripe
  module Webhooks
    module Payouts
      module Offers
        class Paid < BaseAction
          def call
            return if offer.blank?

            logger.info 'Offer payout completed: ' + @event.data.object.id
            send_admin_notifications if check_offer_as_paid_out
          end

          private

          def offer
            @offer ||= Offer.find(payout.metadata[:offer_id])
          end

          def payout
            @payout ||= @event.data.object
          end

          def arrival_date
            Time.zone.at(payout.arrival_date)
          end

          def check_offer_as_paid_out
            offer.update!(status: 'paid_out',
                          paid_out_at: arrival_date)
          end

          def send_admin_notifications
            MarketplaceAdmin.founder.find_each do |admin|
              Marketplace::AdminNotificationsMailer.payout_completed(offer, admin).deliver_now
            end
          end
        end
      end
    end
  end
end
