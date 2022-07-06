# frozen_string_literal: true

# == Schema Information
#
# Table name: hubs
#
#  id                :bigint           not null, primary key
#  name              :string
#  state             :string
#  created_by        :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  hub_process_queue :json             is an Array
#

class Hub < ApplicationRecord
  belongs_to :user, optional: true, foreign_key: :created_by
  has_many :hub_processes

  before_create :format_hub_process_queue
  after_create :initiate_hub_processes
  after_create :launch_first_hub_process

  def launch_next_hub_process(next_queue_position)
    return if hub_process_queue.length < next_queue_position

    hub_process = hub_processes.find_by_queue_position(next_queue_position)
    hub_process.launch_processors
  end

  # apply .to_s to classes as .to_json will process them to {}
  def hub_process_queue=(queue)
    changed_queue = queue.map do |processor_arr|
      processor_arr.map do |processor|
        if processor.is_a?(Hash)
          processor[:processor] = processor[:processor].to_s
          processor
        else
          processor.to_s
        end
      end
    end
    super(changed_queue)
  end

  private

  def format_hub_process_queue
    elements_count = hub_process_queue.map(&:length).max
    hub_process_queue.map { |arr| (elements_count - arr.length).times { arr << nil } }
  end

  def initiate_hub_processes
    hub_process_queue.each_with_index do |processor_array, idx|
      hub_processes.create!(processors: processor_array.reject(&:nil?), queue_position: idx + 1)
    end
  end

  def launch_first_hub_process
    hub_processes.first.launch_processors
  end
end
