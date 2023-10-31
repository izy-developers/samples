module Log
  module_function

  def error_and_notify(msg)
    Rails.logger.error msg
    NotifierService.new(PostToSlackJob).exception(msg)
    nil
  end



  def note(msg, slack: false)
    Rails.logger.info msg
    # logger.info(msg)
    # Notifier.ping(msg) if slack
  end

  def fatal(msg, error_class=false)
    logger.fatal(msg)
    Notifier.ping(msg)
    if error_class.present?
      raise error_class, msg
    else
      raise msg
    end
  end

  def caught_exception(e)
    Notifier.ping("Caught exception: #{e.message}")
    ExceptionNotifier.notify_exception(e)
  end

  def api_bad_request(exception, params)
    email_exception(exception, data: { params: params })
    logger.error(exception.message)
  end

  def save_failure(msg, resource, params)
    email_exception SaveFailure.new(msg), data: {
      params: params,
      errors: resource.errors.messages,
      resource: resource
    }
    logger.error(msg)
  end

  def email_exception(exception, options={})
    ExceptionNotifier.registered_exception_notifier(:email).call(exception, options)
  end

  def logger
    @@logger ||= Logger.new("#{Rails.root}/log/logger.log")
  end
end

class SaveFailure < StandardError; end
