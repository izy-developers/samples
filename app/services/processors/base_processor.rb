# frozen_string_literal: true

module Processors
  class BaseProcessor
    include MonitoringHelper

    attr_accessor :file_location, :log_level, :data_path, :file_name,
                  :valid_min_from, :valid_max_until, :hub_process_id,
                  :job_size, :root_data_path

    def initialize(options = {})
      self.log_level = options[:log_level] || :info
      self.file_name = options[:file_name]
      self.root_data_path = options[:root_data_path] || import_data_path
      self.data_path = "#{root_data_path}/#{options[:path] || 'import_data'}"
      self.file_location = file_location_from_options(options)
      self.valid_min_from = VALID_MIN_FROM
      self.valid_max_until = Time.zone.now.end_of_year + YEARS_TO_IMPORT_FORWARD
      self.hub_process_id = options[:hub_process_id]
      self.job_size = options[:job_size] || 1000
    end

    def run
      previous_log_level = ActiveRecord::Base.logger.level
      ActiveRecord::Base.logger.level = log_level
      send_event_and_log('start_processing')

      time_used, memory_used = run_with_time_and_memory_report do
        before_import
        block_given? ? yield : import
        after_import
      end
      send_event_and_log('end_processing', { time_used_s: time_used, memory_used_mb: memory_used })
      ActiveRecord::Base.logger.level = previous_log_level
    rescue => e
      send_exception(e, self.class.name)
    end

    private

    def import
      file_mapped.each do |row|
        import_row(row)
      end
      GC.start
    end

    def file_mapped
      map_file_with_fallback(file_location, headers_map)
    end

    def map_file_with_fallback(file, headers, options = csv_options)
      send_event_and_log('before_load_file', memory_stats.merge(file: file))

      if xlsx?(file)
        roo_xlsx_map(file, headers)
      else
        memory_optimized_csv_map(file, headers, options)
      end
    rescue CSV::MalformedCSVError
      fallback_options = options.merge(encoding: 'ISO-8859-1')
      roo_csv_map(file, headers, fallback_options)
    ensure
      GC.start
      send_event_and_log('after_load_file', memory_stats.merge(file: file))
    end

    # CAUTION: this is not memory optimized - it loads full csv file into memory
    def roo_csv_map(file, headers, options)
      file = Roo::CSV.new(file, csv_options: options)
      file.each(headers).drop(1)
    end

    def roo_xlsx_map(file, headers)
      raw_import_file = Roo::Spreadsheet.open(file)
      raw_import_file.each(headers).drop(1)
    end

    def memory_optimized_csv_map(file, headers, options = csv_options)
      result = []
      CSV.foreach(file, headers: true, **options) do |row|
        row_hash = headers.inject({}) do |obj, (k, v)|
          obj[k] = row[v]
          obj
        end
        result << row_hash
      end
      result
    end

    def file_location_from_options(options)
      options[:file_location] || "#{data_path}/#{options[:file_name]}"
    end

    def import_row(_row)
      raise NotImplementedError, '#import_row is not implemented'
    end

    def before_import; end

    def after_import; end

    def import_data_path
      IMPORT_DATA_PATH
    end

    def headers_map
      raise NotImplementedError, '#headers_map is not implemented'
    end

    def log(action, message = nil)
      msgs = { action: action, message: message }.compact.map { |k, v| "#{k}=#{v}" }.join(' ')
      Rails.logger.info("processor=#{type} #{msgs}")
    end

    def send_event_and_log(action, payload = {})
      event = payload.merge(group: 'processors', processor: type)
      AzureAppInsightsService.send_event(action, event)
      log(action, payload)
    end

    def send_exception(exception, source)
      properties = { group: 'processors', processor: type }
      AzureAppInsightsService.send_exception(exception, { handled_at: source, properties: properties })
      log('processor_exception', { source: source, message: exception.message })
    end

    def send_import_notification(type, payload)
      send_event_and_log('import_notification', payload.merge(type: type))
    end

    def type
      self.class.name.sub('Processors::', '')
    end

    def xlsx?(location = file_location)
      !!(location =~ /.xlsx\Z/)
    end

    def csv_options
      { col_sep: '|', quote_char: "\x00" }
    end

    def valid_date?(date)
      return true if date > valid_min_from

      log('invalid_date', "date=#{date} expected to be less than #{valid_min_from} years ago")
      false
    end

    def german_sep_number_to_float(value)
      return nil unless value

      out = value.to_s.strip
      out = out.gsub('.', '')
      out.gsub(',', '.').to_f
    end

    def get_file_name(file)
      file.split('/').last
    end

    def launch_processor_jobs(mapped_array, processor_class, file_name, options = {})
      processor_job_bundles = mapped_array.each_slice(job_size)
      create_or_increment_redis_counter(hub_process_id, file_name, processor_job_bundles.size) if hub_process_id
      processor_job_bundles.each do |bundle|
        ProcessorJob.perform_later(hub_process_id, processor_class, file_name, bundle, options)
      end
    end

    def launch_processor_job(processor_class, file_name, options)
      create_or_increment_redis_counter(hub_process_id, file_name, 1) if hub_process_id
      ProcessorJob.perform_later(hub_process_id, processor_class, file_name, nil, options)
    end

    def create_or_increment_redis_counter(hub_process_id, key, number)
      HubJobsPool.create_or_increment_counter(hub_process_id, key, number)
    end

    def for_each_month(from, to)
      current = from.beginning_of_month

      while current <= to
        yield(current)
        current += 1.month
      end
    end
  end
end
