# frozen_string_literal: true

class HubJobsPool
  HUB_PROCESS_KEY = ENV.fetch('HUB_PROCESS_KEY', 'hub_process_').to_s

  class << self
    def finalize_job(hub_process_id, key)
      name = object_name(hub_process_id)
      Sidekiq.redis { |c| c.hincrby(name, key, -1) }
      left = Sidekiq.redis { |c| c.hgetall(name) }.inject(0) { |sum, file_counter| sum + file_counter[1].to_i }

      Rails.logger.info("source=#{key} action=job_finished hub_process=#{hub_process_id} threads_left=#{left}")

      return unless left.zero?

      Rails.logger.info("source=#{key} action=import_finished hub_process_id=#{hub_process_id}")
      HubProcess.find(hub_process_id).finish
    end

    def create_or_increment_counter(id, key, count)
      Sidekiq.redis { |c| c.hincrby("#{HUB_PROCESS_KEY}#{id}", key, count) }
    end

    def get_pool(id)
      Sidekiq.redis { |c| c.hgetall(object_name(id)) }
    end

    def object_name(id)
      "#{HUB_PROCESS_KEY}#{id}"
    end
  end
end
