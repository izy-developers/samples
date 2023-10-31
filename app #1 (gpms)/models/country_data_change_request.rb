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
class CountryDataChangeRequest < DataChangeRequest
  include AASM

  aasm(:status) do
    state :initialized, initial: true
    state :submitted, :approved, :approved_one, :rejected, :finished_one, :finished, :discarded

    event :submit do
      after do
        update_history(true)
        review_brand_data_change_requests
      end
      transitions from: %i[rejected initialized], to: :submitted
    end

    event :approve_one do
      after do
        update_history(false)
        review
      end
      transitions from: [:submitted], to: :approved_one
    end

    event :approve do
      after do
        update_history(true)
        export_price_changes(true)
      end
      transitions from: [:approved_one], to: :approved
    end

    event :reject do
      after do
        update_history(true)
        unreview
        unreview_brand_data_change_requests
      end
      transitions from: %i[
        initialized submitted approved approved_one finished_one rejected
      ], to: :rejected
    end

    event :finish_one do
      after do
        update_history(false)
      end
      transitions from: [:approved], to: :finished_one
    end

    event :finish do
      after_commit do
        finish_price_planning
        export_price_changes(false)
        update_history(true)
        historize_data
      end
      transitions from: [:finished_one], to: :finished
    end

    event :discard do
      before :notify_discarded
      after  :destroy
      transitions from: %i[initialized submitted approved rejected discarded finished_one approved_one], to: :discarded
    end
  end

  after_create do
    update_history(false)
  end

  before_destroy do
    brand_data_change_requests.find_each(&:discard!)
  end

  APPROVE_EMAIL_RECEIVERS = %w[
    mob mob_gb mob_dep gpo global_forecast_manager
  ].freeze
  APPROVE_EMAIL_RECEIVERS_BY_COUNTRY = %w[
    country_head deputy_country_head brand_manager area_sales_manager
    head_of_marketing distribution_manager marketing_analyst
  ].freeze

  FINISH_EMAIL_RECEIVERS = %w[
    mob mob_gb mob_dep gpo head_of_global_marketing global_brand_manager global_forecast_manager
  ].freeze
  FINISH_EMAIL_RECEIVERS_BY_COUNTRY = %w[
    country_head deputy_country_head brand_manager head_of_marketing distribution_manager
    marketing_analyst country_support_manager area_sales_manager
  ].freeze

  has_many   :brand_data_change_requests, as: :parent
  belongs_to :price_planning

  def as_info(limited = false)
    corrections = data_change_request_corrections.order('created_at DESC')
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
      corrections: corrections.map do |correction|
        {
          user: correction.user.as_info(true),
          valid_from: correction.valid_from.to_date.to_s,
          valid_until: correction.valid_until.to_date.to_s,
          created_at: correction.created_at,
          status: correction.status,
          values: correction.values,
          comment: correction.comment
        }
      end
    )

    unless limited
      result.merge!(
        object: changeable,
        object_id: changeable.id,
        object_name: changeable.name
      )
    end

    result
  end

  def product_data_change_requests
    ProductDataChangeRequest.where(parent: brand_data_change_requests)
  end

  def set_name
    self.name = "#{changeable.name} price change"
  end

  def responder
    initiator
  end

  def country
    changeable
  end

  def notified_users
    case status
    when 'approved'
      User.with_role(APPROVE_EMAIL_RECEIVERS) +
        changeable.users.with_role(APPROVE_EMAIL_RECEIVERS_BY_COUNTRY)
    when 'finished_one', 'finished'
      User.with_role(FINISH_EMAIL_RECEIVERS) +
        changeable.users.with_role(FINISH_EMAIL_RECEIVERS_BY_COUNTRY)
    when 'submitted'
      changeable.users.with_role(%w[country_head deputy_country_head head_of_marketing]) + User.gpo
    when 'rejected'
      changeable.users.with_role(
        %w[brand_manager area_sales_manager head_of_marketing distribution_manager marketing_analyst]
      ) + User.gpo
    end
  end

  def next_approve_step
    if submitted?
      :approve_one!
    elsif approved_one?
      :approve!
    end
  end

  def next_finish_step
    if approved?
      :finish_one!
    elsif finished_one?
      :finish!
    end
  end

  def review_brand_data_change_requests
    brand_data_change_requests.each(&:review)
  end

  def unreview_brand_data_change_requests
    brand_data_change_requests.each(&:unreview)
  end

  def export_price_changes(gpo_approved = false)
    ExportPriceChangesJob.perform_later(
      product_data_change_requests_ids: product_data_change_requests.not_skipped.ids,
      gpo_approved: gpo_approved
    )
  end

  def finish_price_planning
    brand_data_change_requests.each do |bdcr|
      bdcr.history_options = history_options
      bdcr.finish!
    end
  end

  def periodical_data(with_history = true)
    return JSON.parse(history_data) if finished? && history_data.present? && with_history

    pdcrs = ProductDataChangeRequest.not_skipped
                                    .where(parent_id: brand_data_change_requests.ids)
                                    .sort_by { |pdcr| pdcr.changeable.gpms_name }
    pdcrs.group_by(&:changeable_id).each_with_object([]) do |(k,v), arr|
      arr << ProfitCenterVariant.find(k).periodical_data(v.sort_by(&:valid_from), changeable)
    end
  end
end
