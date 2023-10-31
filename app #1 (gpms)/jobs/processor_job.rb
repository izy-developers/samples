# frozen_string_literal: true

class ProcessorJob < ApplicationJob
  queue_as :import
  sidekiq_options retry: false

  def perform(hub_process_id, processor_class, key, bundle, options = {})
    processor_class.new(options.merge(bundle: bundle)).run
    HubJobsPool.finalize_job(hub_process_id, key) if hub_process_id
  end
end
