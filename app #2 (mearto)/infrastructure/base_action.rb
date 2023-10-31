# frozen_string_literal: true

class BaseAction
  class NonKeywordArgumentsError < StandardError; end

  def self.call(*args, **kwargs, &block)
    new(*args, **kwargs, &block).call
  end

  attr_reader :args, :data

  def initialize(**args)
    return if args.blank?

    raise NonKeywordArgumentsError if args.present? && !args.is_a?(Hash)

    @args = @data = args

    @args.each do |name, value|
      instance_variable_set("@#{name}", value)
    end

    yield if block_given?
  end

  def call; end

  def response(status, *args)
    BaseResponse.new(status, *args)
  end

  def handle_webhook
    yield
    response(:success, args.merge!(event: event, message: @message))
  rescue StandardError => e
    response(:fail, args.merge!(event: event, errors: e))
  end

  def event_not_handling
    logger.info 'We are not handling: ' + event.type
    logger.info 'Event payload: ' + event.to_json
  end

  def logger
    Rails.logger
  end
end
