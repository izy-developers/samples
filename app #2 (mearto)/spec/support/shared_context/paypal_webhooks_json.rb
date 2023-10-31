# frozen_string_literal: true

RSpec.shared_context 'paypal webhooks json' do
  def bild_paypal_json(id, type)
    { id: SecureRandom.hex(10),
      create_time: Time.now,
      resource_type: 'sale complete',
      event_type: type,
      summary: 'Payment',
      resource: {
        id: SecureRandom.hex(10),
        create_time: Time.now,
        update_time: Time.now,
        amount: {
          total: '5.45',
          currency: 'USD',
          details: {
            subtotal: '5.45'
          }
        },
        parent_payment: id,
        valid_until: Time.now + 1.month
      } }
  end
end
