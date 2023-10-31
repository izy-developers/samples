# frozen_string_literal: true

class Items::Forms::Create < BaseForm
  PERMITTED_ATTRIBUTES = %i[category_id channel_id seller_id title description
    dimensions acquired_from provenance is_for_sale response_time asking_price
    currency marketplace_terms_of_service private on_marketplace state].freeze
  REQUIRED_ATTRIBUTES = %i[category_id title description acquired_from].freeze
  attr_accessor(*PERMITTED_ATTRIBUTES, :record)

  validate :ready_for_marketplace?

  private

  def ready_for_marketplace?
    return if response_time.present? && private.present?

    # return unless for_sale?

    # validate_asking_price
    # validate_terms_of_service
  end

  def for_sale?
    %w[Yes Maybe].include?(is_for_sale)
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
