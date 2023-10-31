# frozen_string_literal: true

module Attachments
  class EventService
    def initialize(attachment_id)
      @attachment_id = attachment_id
      @event = create_event
    end

    def create_event
      AttachmentParsingEvent.find_or_create_by(
        attachment_id: @attachment_id,
        status: AttachmentParsingEvent::INIT_STATUS
      )
    end

    def in_progress_status
      @event.update(status: AttachmentParsingEvent::IN_PROGRESS_STATUS)
    end

    def succeed_status
      @event.update(status: AttachmentParsingEvent::SUCCEED_STATUS)
    end

    def failed_status
      @event.update(status: AttachmentParsingEvent::FAILED_STATUS)
    end
  end
end
