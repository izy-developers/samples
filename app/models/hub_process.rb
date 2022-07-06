# frozen_string_literal: true

# == Schema Information
#
# Table name: hub_processes
#
#  id             :bigint           not null, primary key
#  queue_position :integer
#  state          :string
#  hub_id         :bigint
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  processors     :json             is an Array
#
class HubProcess < ApplicationRecord
  belongs_to :hub

  # Creates redis object with records for each processor having processor class name as a key
  # and value equal 1 (processor quantity)
  # Example: "hub_process_1: { 'Processor1': 1, 'Processor2': 1 }"
  def launch_processors(delay = 0)
    processors.each do |processor|

      processor_class, options = if processor.is_a?(Hash)
                                   [processor['processor'], processor['options'] || {}]
                                 else
                                   [processor, {}]
                                 end
      HubJobsPool.create_or_increment_counter(id, processor_class, 1)
      HubProcessJob.set(wait: delay).perform_later(id, processor_class, options)
    end
  end

  def finish
    next_queue_position = queue_position + 1
    hub.launch_next_hub_process(next_queue_position)
  end
end
