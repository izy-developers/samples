# frozen_string_literal: true

class UploadHistoricRatesJob < ApplicationJob
  queue_as :uploads
  sidekiq_options retry: false

  def perform(options)
    data_change_request = DataChangeRequest.find(options[:data_change_request_id])

    Currencies::HistoricRatesUploader.new(
      currency_id: data_change_request.changeable.id,
      value: data_change_request.values[data_change_request.field].to_f,
      field: data_change_request.field,
      valid_from: data_change_request.valid_from,
      valid_until: data_change_request.valid_until
    ).run

    data_change_request.upload!
  rescue => e
    properties = {
      group: 'data_change_requests',
      class: 'UploadHistoricRatesJob',
    }.merge!(options)

    send_exception(e, properties)
  end
end
