class SendSmsJob < ApplicationJob
  queue_as :default

  def perform(body,recipient)
    client = Twilio::REST::Client.new
    begin
      client.messages.create(
        from: TWILIO_DEFAULT_SENDER,
        messaging_service_sid: MESSAGING_SERVICE,
        to: recipient,
        body: body
      )
    rescue => exception
      Rollbar.error(exception)
      puts "-> Could not send message: #{exception.message}"
    end
  end
  
end