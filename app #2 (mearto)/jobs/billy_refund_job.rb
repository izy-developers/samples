class BillyRefundJob < ApplicationJob
  queue_as :default

  # Dont retry job if there is an error - else it will create multiple invoices in Billy
  rescue_from(StandardError) do |exception|
    Log.error_and_notify("[#{self.class.name}] Error: #{exception.to_s} #{exception.backtrace} \n Invoice: #{@refund_invoice.to_json}")
  end

  def perform(invoice_id)

    @refund_invoice = Invoice.find(invoice_id)

    billy_invoice = BillyAccounting.create_refund_invoice(@refund_invoice)
    @refund_invoice.billy_id = billy_invoice['id']
    @refund_invoice.billy_data = billy_invoice

    billy_payment = BillyAccounting.create_refund_payment(@refund_invoice)
    @refund_invoice.billy_payment_id = billy_payment['id']

    @refund_invoice.pdf = BillyAccounting.download_invoice(@refund_invoice)
    @refund_invoice.save!

    # TODO: Maybe email the invoice to the user
  end

end
