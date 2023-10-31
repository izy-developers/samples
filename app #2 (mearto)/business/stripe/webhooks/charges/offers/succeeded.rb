# frozen_string_literal: true

module Stripe
  module Webhooks
    module Charges
      module Offers
        class Succeeded < BaseAction
          def call
            return if offer.offer_invoice.present? && offer.paid?

            offer.transaction do
              create_offer_invoice
              check_offer_as_paid
              send_notification_email
              send_admin_notification
              set_delayed_warning_for_seller
              set_delayed_cancelation
            end
          end

          private

          attr_reader :event, :invoice

          def offer
            @offer ||= Offer.find(charge.metadata[:offer_id])
          end

          def charge_created
            Time.zone.at(charge.created)
          end

          def check_offer_as_paid
            offer.update!(status: 'paid',
                          paid_at: charge_created)
          end

          def charge
            @charge ||= @event.data.object
          end

          def stripe_customer
            @stripe_customer ||= ::Stripe::Customer.retrieve(charge.customer)
          end

          def buyer
            @buyer = User.find_by(email: stripe_customer.email)
          end

          def balance_transaction
            @balance_transaction ||= ::Stripe::BalanceTransaction.retrieve(charge.balance_transaction)
          end

          def create_offer_invoice
            @invoice = OfferInvoice.create!(
              user_id: buyer.id,
              offer_id: offer.id,
              invoice_date: Time.at(charge.created),
              subtotal_amount: calc_subtotal_amount,
              total_amount: charge.amount,
              currency: charge.currency,
              paid: charge.paid,
              closed: true,
              lines: nil,
              total_dkk_amount: balance_transaction.try(:amount),
              stripe_id: charge.id,
              stripe_charge: charge,
              stripe_balance_transaction: balance_transaction
            )
          end

          def calc_subtotal_amount
            charge.amount - charge.application_fee_amount
          end

          def send_notification_email
            Marketplace::SellerNotificationsMailer.offer_needs_shipping_details(offer).deliver_now
          end

          def set_delayed_warning_for_seller
            Marketplace::DelayedMailers::RequireActionWarningJob.set(wait: Offer::PENDING_WARNING_MESSAGE_PERIOD)
                                                                .perform_later(options: { offer: offer, user: offer.seller },
                                                                               action: 'shipping_details_required')
          end

          def set_delayed_cancelation
            Marketplace::AutoCancelation::ShippingDetailsAutoCancelJob.set(wait: Offer::AUTO_CANCELATION_PERIOD)
                                                                      .perform_later(offer)
          end

          def send_admin_notification
            MarketplaceAdmin.find_each do |admin|
              Marketplace::AdminNotificationsMailer.offer_update(offer, admin).deliver_now
            end
          end
        end
      end
    end
  end
end
