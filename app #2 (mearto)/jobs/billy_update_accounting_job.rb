class BillyUpdateAccountingJob < ApplicationJob
  queue_as :default

  # Dont retry job if there is an error - else it will create multiple invoices in Billy
  rescue_from(StandardError) do |exception|
    msg = "[#{self.class.name}] Error: #{exception.to_s} #{exception.backtrace} \n User: #{@user.to_json}, Invoice: #{@invoice.id}"
    NotifierService.new(PostToSlackJob).exception(msg)
    # Log.error_and_notify("[#{self.class.name}] Error: #{exception.to_s} #{exception.backtrace} \n User: #{@user.to_json}, Invoice: #{@invoice.id}")
  end

  def perform(user_id, invoice_id)
    @user = User.find(user_id)
    @invoice = Invoice.find(invoice_id)

    billy_contact = BillyAccounting.create_contact(@user)
    if !billy_contact.nil?
      @user.billy_id = billy_contact['id']
      @user.save!
    end

    billy_invoice = BillyAccounting.create_invoice(@invoice)
    if !billy_invoice.nil?
      @invoice.billy_id = billy_invoice['id']
      @invoice.billy_data = billy_invoice
    end

    billy_payment = BillyAccounting.create_payment(@invoice)
    @invoice.billy_payment_id = billy_payment['id']
    @invoice.pdf = BillyAccounting.download_invoice(@invoice)
    @invoice.save!

    # TODO: Maybe email the invoice to the user
  end

end
