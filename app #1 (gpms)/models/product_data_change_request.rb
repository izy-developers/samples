# frozen_string_literal: true

# == Schema Information
#
# Table name: data_change_requests
#
#  id                :bigint           not null, primary key
#  name              :string
#  status            :string           default("initialized")
#  field             :string
#  changeable_type   :string
#  changeable_id     :bigint
#  initiator_id      :bigint
#  valid_from        :datetime
#  valid_until       :datetime
#  values            :json
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  type              :string
#  parent_type       :string
#  parent_id         :bigint
#  price_planning_id :bigint
#
class ProductDataChangeRequest < DataChangeRequest
  include AASM

  aasm(:status) do
    state :initialized, initial: true
    state :approved, :rejected, :finished, :discarded

    event :approve do
      after do
        update_history(false)
        review
      end
      transitions from: %i[initialized rejected], to: :approved, guards: %i[unique_data_period]
    end

    event :reject do
      after do
        update_history(false)
        reject_brand_data_change_request
        unreview
      end
      transitions from: %i[initialized approved rejected], to: :rejected
    end

    event :finish do
      before :update_changeable
      after_commit do
        update_history(false)
        historize_data
      end
      transitions from: [:approved], to: :finished, guard: :unique_data_period
    end

    event :discard do
      after :destroy, :reject_brand_data_change_request
      transitions from: %i[initialized approved rejected discarded], to: :discarded
    end
  end

  after_create do
    update_history(false)
  end

  after_commit do
    brand_data_change_request&.update_dates_from_pdcr
    country_data_change_request&.update_dates_from_pdcr
  end

  after_update :update_price_change_request_dates

  has_one    :price_change_request, dependent: :destroy
  belongs_to :price_planning

  scope :for_periodical_data, -> { not_finished.not_skipped.includes(:price_change_request).where.not(price_change_request: { id: nil }) }

  def as_info(limited = false)
    result = attributes.merge(
      valid_from: valid_from.to_date.to_s,
      valid_until: valid_until.to_date.to_s,
      last_modified: corrections[0].created_at.to_date.to_s,
      last_correction: corrections[0].values[field].to_f,
      initiator: initiator.account_type_humanize,
      responder: responder&.full_name,
      field_name: field_name,
      reviewed: reviewed,
      comments: Comment.for_commentable(self.class.to_s, 'price_planning', id).order('created_at DESC').map(&:as_info),
      corrections: corrections.map(&:as_info),
      type: self.class,
    )

    unless limited
      result.merge!(
        object: changeable,
        object_id: changeable.id,
        object_name: changeable.gpms_name
      )
    end

    result
  end

  def reject_brand_data_change_request
    return if brand_data_change_request&.rejected? || brand_data_change_request&.discarded?

    brand_data_change_request.history_options = history_options
    brand_data_change_request.reject!
  end

  def set_name
    self.name = "#{changeable_type} price buildup changes"
  end

  def responder
    initiator
  end

  def country
    parent.parent.changeable
  end

  def brand_data_change_request
    parent
  end

  def country_data_change_request
    parent&.parent
  end

  def update_changeable
    price_change_request&.update_from_change_request
  end

  def update_price_change_request_dates
    return unless saved_change_to_valid_from? ||
      saved_change_to_valid_until? ||
      price_change_request.valid_from != valid_from ||
      price_change_request.valid_until != valid_until

    price_change_request.update(valid_from: valid_from, valid_until: valid_until)
  end

  def periodical_data(with_history = true)
    return JSON.parse(history_data) if finished? && history_data.present? && with_history

    [changeable.periodical_data([self], parent&.parent&.changeable)]
  end
end
