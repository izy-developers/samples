# frozen_string_literal: true

class Items::Forms::Update < BaseForm
  PERMITTED_ATTRIBUTES = %i[response_time private title description dimensions acquired_from provenance
                            seller_estimate condition category_id top_category_id sub_category_id
                            is_for_sale artist_id asking_price currency marketplace_terms_of_service
                            private images item_images_attributes seller_attributes reason_for_appraisal].freeze
  REQUIRED_ATTRIBUTES = %i[title top_category_id is_for_sale acquired_from description].freeze
  attr_accessor(*PERMITTED_ATTRIBUTES, :record)

  validate :ready_for_marketplace?, :validate_response_time

  def for_sale?
    %w[Yes Maybe].include?(is_for_sale)
  end

  def appraisal_has_sap?
    return if record_appraisal.blank?

    record_appraisal.suggested_asking_price.positive?
  end

  private

  def record_appraisal
    @record_appraisal ||= record.mearto_appraisals.first
  end

  def validate_response_time
    return if record.is_paid_for? || record_appraisal.present?

    errors.add(:response_time, "can't be blank") if response_time.blank?
  end

  def ready_for_marketplace?
    return unless for_sale? && appraisal_has_sap?

    validate_asking_price
    validate_terms_of_service
  end

  def validate_asking_price
    errors.add(:asking_price, "can't be empty or zero if you want sell the item") unless asking_price_set?
    errors.add(:asking_price, 'for items in the Mearto Marketplace must be at least 50') if asking_price_low?
  end

  def validate_terms_of_service
    errors.add(:marketplace_terms_of_service, "can't be unchecked if you want sell the item") unless terms_of_service_checked?
  end

  def asking_price_set?
    asking_price&.to_i&.positive? && currency.present?
  end

  def asking_price_low?
    asking_price.to_i.between?(1, 49)
  end

  def terms_of_service_checked?
    marketplace_terms_of_service == '1'
  end
end
