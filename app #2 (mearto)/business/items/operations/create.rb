# frozen_string_literal: true

class Items::Operations::Create < BaseOperation
  def call
    build_record
    prepare_params
    move_to_marketplace unless needs_appraisal?
    build_form
    return validation_fail unless form_valid?

    assign_attributes
    return validation_fail unless save_record

    success(args.merge!(record: record))
  end

  private

  attr_reader :appraisal_question

  def form_class
    Items::Forms::Create
  end

  def build_record
    @record = Item.new
  end

  def needs_appraisal?
    ActiveModel::Type::Boolean.new.cast(appraisal_question)
  end

  # We removed choose between 24h & 48h on item form,
  # setting 48 for every item.
  def prepare_params
    record_params.merge!(response_time: 48)
  end

  def move_to_marketplace
    record_params.merge!(is_for_sale: 'Yes', on_marketplace: true)
  end
end
