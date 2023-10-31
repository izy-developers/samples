# frozen_string_literal: true

module Stripe
  module Webhooks
    module Charges
      module Offers
        class Refunded < BaseAction
          def call
            return if offer.offer_invoice.blank?

            offer.transaction do
              create_refund_invoice
              offer.update!(status: 'refunded')
              offer.item.update(on_marketplace: true)
            end
          end

          private

          def offer
            @offer ||= Offer.find(refund.metadata[:offer_id])
          end

          def refund
            @refund ||= @event.data.object
          end

          def balance_transaction
            @balance_transaction ||= Stripe::BalanceTransaction.retrieve(refund.balance_transaction)
          end

          def refund_obj
            @refund_obj ||= { amount: refund.amount,
                              created: Time.zone.at(refund.created),
                              currency: refund.currency,
                              data: refund,
                              total_dkk_amount: -balance_transaction.try(:amount),
                              credited_invoice: offer.offer_invoice,
                              balance_transaction: balance_transaction }
          end

          def create_refund_invoice
            @invoice = ::Refund.create(
              credited_invoice: refund_obj[:credited_invoice],
              user_id: refund_obj[:credited_invoice].user_id,
              invoice_date: refund_obj[:created],
              subtotal_amount: -refund_obj[:amount],
              total_amount: -refund_obj[:amount],
              currency: refund_obj[:currency],
              tax_percent: offer.offer_invoice.user.country&.vat_rate,
              paid: true,
              closed: true,
              lines: nil,
              total_dkk_amount: -refund_obj[:total_dkk_amount],
              refund_data: refund_obj[:data],
              stripe_balance_transaction: refund_obj[:balance_transaction]
            )
          end
        end
      end
    end
  end
end
