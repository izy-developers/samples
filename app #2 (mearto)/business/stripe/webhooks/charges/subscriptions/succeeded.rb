# frozen_string_literal: true

module Stripe
  module Webhooks
    module Charges
      module Subscriptions
        # If the charge came from paid appraisal - then we have already saved it,
        # but if it comes from a subscription - then we need to save it
        # Paid appraisal charge has no invoice - only subscriptions
        class Succeeded < BaseAction
          def call
            fetch_balance_transaction
            return if charge.invoice.blank?

            fetch_stripe_invoice
            return if first_line.blank?

            fetch_subscription
            fetch_stripe_customer
            fetch_user
            create_payment
            create_subscription_invoice
            update_billy
          end

          private

          attr_reader :event, :payment, :invoice, :stripe_invoice,
                      :subscription, :stripe_customer, :user, :balance_transaction

          def charge
            @charge ||= event.data.object
          end

          def fetch_balance_transaction
            @balance_transaction = Stripe::BalanceTransaction.retrieve(charge.balance_transaction)
          end

          def fetch_stripe_invoice
            @stripe_invoice = Stripe::Invoice.retrieve(charge.invoice)
          end

          def first_line
            @first_line ||= stripe_invoice.lines.data.first
          end

          def fetch_subscription
            @subscription = ::Subscription.find_by(stripe_subscription_id: first_line.id)
          end

          def fetch_stripe_customer
            @stripe_customer = Stripe::Customer.retrieve(charge.customer)
          end

          def fetch_user
            @user = User.find_by(email: stripe_customer.email)
          end

          def create_payment
            # Store the payment for future reference
            @payment = Payment.create(
              subscription: subscription,
              stripe_customer_id: charge.customer,
              stripe_plan_id: first_line.plan.name,
              stripe_subscription_id: first_line.id,
              success: charge.paid,
              paid_at: Time.at(event.created).to_datetime,
              updated_at: Time.now,
              period_start: Time.at(first_line.period.start).to_datetime,
              period_end: Time.at(first_line.period.end).to_datetime,
              currency: stripe_invoice.currency,
              amount_net: stripe_invoice.subtotal,
              amount_total: stripe_invoice.amount_due
            )
          end

          def create_subscription_invoice
            @invoice = SubscriptionInvoice.create(
              user_id: user.id,
              invoice_date: Time.at(charge.created),
              subtotal_amount: stripe_invoice.subtotal,
              total_amount: stripe_invoice.amount_due,
              currency: charge.currency,
              tax_percent: stripe_invoice.tax_percent,
              paid: charge.paid,
              closed: true,
              lines: nil,
              total_dkk_amount: balance_transaction.try(:amount),
              stripe_id: stripe_invoice.id,
              stripe_charge: charge,
              stripe_balance_transaction: balance_transaction,
              stripe_discount: stripe_invoice.discount
            )
          end

          def update_billy
            BillyUpdateAccountingJob.perform_later(user.id, invoice.id) if Rails.env.production?
          end
        end
      end
    end
  end
end
