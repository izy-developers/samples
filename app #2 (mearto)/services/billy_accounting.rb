class BillyAccounting

  def self.create_contact(user)
    # No need to create a billy contact if user already is attached to one
    return unless user.billy_id.nil?

    billy_contact_params = {
      isCustomer: 1,
      type: 'person',
      name: user.fullname,
      countryId: user.country_id,
      localeId: 'en_US',
      contactPersons: [
        {
          name: user.fullname,
          email: user.email
        }
      ]
    }
    # Create new customer in Billy
    BillyClient.create('contact', billy_contact_params)
  end

  def self.create_invoice(invoice)
    # unit_price_ex_tax = ((invoice.total_amount.to_f/100) / ((invoice.tax_percent.to_f/100) + 1)).round(4)
    if invoice.is_tax_included?
      unit_price = (invoice.total_amount.to_f/100)
      tax_mode = 'incl'
    else
      unit_price = invoice.subtotal_amount.to_f/100
      tax_mode = 'excl'
    end

    # unit_price = (invoice.total_amount.to_f/100)
    invoice_lines = [{
      productId: invoice.product_id,
      description: invoice.description,
      quantity: 1,
      unitPrice: unit_price
    }]

    if invoice.has_discount?
      if invoice.discount_mode == 'cash'
        invoice_lines.each do |line|
          if line[:unitPrice].positive?
            line.merge!(
              discountMode: 'cash',
              discountValue: invoice.discount_total.to_f
            )
            break
          end
        end

      # If percent discount, apply it to all positive invoice lines.
      elsif invoice.discount_mode == 'percent'
        invoice_lines.each do |line|
          if line[:unitPrice].positive?
            line.merge!(
              discountMode: 'percent',
              discountValue: invoice.discount_value
            )
          end
        end
      end
    end

    billy_invoice_params = {
      contactId: invoice.user.billy_id,
      entryDate: invoice.invoice_date,
      currencyId: invoice.currency,
      lines: invoice_lines,
      state: 'approved',
      taxMode: tax_mode,
      paymentTermsDays: 0
    }

    # Create invoice in Billy
    BillyClient.create('invoice', billy_invoice_params)
  end


  def self.create_payment(invoice)
    if invoice.billy_id.blank?
      Log.error_and_notify "Tried to create payment for invoice #{invoice.id} without billy_id."
      raise msg
    end

    # stripe_balance_transaction is JSON data from db
    # Use this when you need to account for Stripe fees in Billy - Currently fees are free and are adjusted in Stripe
    # balance as Seier Capital Credit
    transaction = invoice.stripe_balance_transaction

    # Billy only accepts 6 decimals.
    exchange_rate = (invoice.total_dkk_amount.to_f / invoice.total_amount.to_f).round(6)

    billy_payment_params = {
      entryDate: invoice.invoice_date,
      # cashAmount is the payment in DKK minus Stripe fee - It has to be in DKK because the Billy account is set to DKK
      # cashAmount: (transaction.amount.to_f-transaction.fee.to_f)/100, # The payment amount in DKK minus Stripe fee.
      cashAmount: invoice.total_dkk_amount.to_f/100,
      cashSide: 'debit',
      cashAccountId: Rails.application.secrets.billy[:accounts][:stripe_debt],
      cashExchangeRate: exchange_rate,
      # feeAmount: transaction.fee.to_f/100, # Stripe fee in DKK.
      # feeAccountId: Rails.application.secrets.billy[:accounts][:stripe_fee],
      associations: [
        {
          subjectReference: "invoice:#{invoice.billy_id}"
        }
      ]
    }

    BillyClient.create('bankPayment', billy_payment_params)
  end

  def self.download_invoice(invoice)
    URI.parse invoice.billy_data['downloadUrl']
  end

  def self.create_refund_invoice(invoice)
    # unit_price_ex_tax = ((invoice.total_amount.to_f/100) / ((invoice.tax_percent.to_f/100) + 1)).round(4)
    unit_price = invoice.total_amount.abs.to_f/100
    invoice_lines = [{
      productId: Rails.application.secrets.billy[:products][:appraisal],
      description: "Refund from Mearto.com",
      quantity: 1,
      unitPrice: unit_price
    }]

    billy_invoice_params = {
      contactId: invoice.user.billy_id,
      entryDate: invoice.invoice_date,
      currencyId: invoice.currency,
      type: 'creditNote',
      lines: invoice_lines,
      state: 'approved',
      taxMode: 'incl',
      creditedInvoiceId: invoice.credited_invoice.billy_id
    }
    # Create invoice in Billy
    BillyClient.create('invoice', billy_invoice_params)
  end

  def self.create_refund_payment(refund_invoice)
    # Billy only accepts 6 decimals.
    exchange_rate = (refund_invoice.total_dkk_amount.to_f / refund_invoice.total_amount.to_f).round(6)
    billy_payment_params = {
      entryDate: refund_invoice.invoice_date,
      cashAmount: refund_invoice.total_dkk_amount.abs.to_f/100,
      cashSide: 'credit',
      cashAccountId: Rails.application.secrets.billy[:accounts][:stripe_debt],
      cashExchangeRate: exchange_rate,
      associations: [
        {
          subjectReference: "invoice:#{refund_invoice.billy_id}"
        }
      ]
    }
    BillyClient.create('bankPayment', billy_payment_params)
  end

end
