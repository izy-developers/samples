# frozen_string_literal: true

module Stripe
  class TransactionService
    class << self
      def call(event)
        checkout_session = event['data']['object']

        transactions = Transaction.where(session: checkout_session['payment_intent'])
        transactions.each { |t| complete_transaction!(t) }
      end

      private

      def complete_transaction!(transaction)
        transaction.complete!
        return unless transaction.transaction_type == 'top_up_and_purchase'

        Transactions::PurchaseService.new(
          attachment: Attachment.find(transaction.attachment_id),
          user: transaction.user
        ).call
      end
    end
  end
end
