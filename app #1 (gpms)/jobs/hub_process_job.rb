# frozen_string_literal: true

class HubProcessJob < ApplicationJob
  queue_as :import
  sidekiq_options retry: false

  def perform(hub_process_id, processor_class, options = {})
    params = {
      hub_process_id: hub_process_id
    }.merge(options.symbolize_keys)
    processor_class.constantize.new(params).run

    HubJobsPool.finalize_job(hub_process_id, processor_class)
  end
end
