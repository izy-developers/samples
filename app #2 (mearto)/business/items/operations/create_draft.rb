# frozen_string_literal: true

class Items::Operations::CreateDraft < Items::Operations::Create
  def call
    build_record
    prepare_params
    move_to_marketplace unless needs_appraisal?
    build_form

    assign_attributes
    record.save!(validate: false)

    success(args.merge!(record: record))
  end

  private

  def prepare_params
    super
    record_params.merge!(state: :draft)
  end
end
