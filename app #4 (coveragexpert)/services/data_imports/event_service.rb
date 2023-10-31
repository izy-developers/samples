# frozen_string_literal: true

module DataImports
  class EventService
    def initialize(data_import_id)
      @data_import_id = data_import_id
      @event = create_event
    end

    def create_event
      DataImportEvent.find_or_create_by(
        data_import_id: @data_import_id,
        status: DataImportEvent::INIT_STATUS
      )
    end

    def in_progress_status
      @event.update(status: DataImportEvent::IN_PROGRESS_STATUS)
    end

    def succeed_status
      @event.update(status: DataImportEvent::SUCCEED_STATUS)
    end

    def failed_status
      @event.update(status: DataImportEvent::FAILED_STATUS)
    end
  end
end
