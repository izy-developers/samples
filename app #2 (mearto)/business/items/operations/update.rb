# frozen_string_literal: true

class Items::Operations::Update < BaseOperation
  def call
    prepare_params
    build_form
    return validation_fail unless form_valid?

    check_marketplace_status
    if !form.appraisal_has_sap? && form.for_sale?
      send_notifications
      update_record_state
    end

    if can_move_to_open?
      record_params[:state] = 'open'
    end

    assign_attributes
    return validation_fail unless save_record

    success(args)
  end

  private

  def can_move_to_open?
    record.draft? && record.errors.empty? && record.item_images.any?
  end

  def check_marketplace_status
    return record_params[:on_marketplace] = true if asking_price_in_range? && form.for_sale?

    record_params[:on_marketplace] = false
    record_params[:marketplace_terms_of_service] = false
  end

  def send_notifications
    SpecialistMailer.notify_about_waiting_sap(record.assignee, record).deliver_now if record.assignee.present?
  end

  def update_record_state
    record_params[:state] = 'in_dialog'
  end

  def form_class
    Items::Forms::Update
  end

  def prepare_params
    record_params.merge!(response_time: 48)
  end

  def asking_price_in_range?
    Item::MARKETPLACE_PRICE_RAGE.to_a.include?(record_params[:asking_price].to_i * 100)
  end
end
