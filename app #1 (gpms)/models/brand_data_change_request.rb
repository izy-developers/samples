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
class BrandDataChangeRequest < DataChangeRequest
  include AASM

  aasm(:status) do
    state :initialized, initial: true
    state :submitted, :approved, :approved_one, :approved_two, :rejected, :finished, :discarded

    event :submit do
      after do
        update_history(true)
        review_product_data_change_requests
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

    event :approve_two do
      after do
        update_history(false)
      end
      transitions from: [:approved_one], to: :approved_two
    end

    event :approve do
      after do
        update_history(true)
      end
      transitions from: %i[submitted approved_one approved_two], to: :approved
    end

    event :reject do
      after do
        update_history(true)
        unreview
        reject_country_data_change_request
        unreview_product_data_change_requests
      end
      transitions from: %i[initialized submitted approved approved_one approved_two rejected], to: :rejected
    end

    event :finish do
      after_commit do
        finish_price_planning
        update_history(false)
        historize_data
      end
      transitions from: [:approved], to: :finished
    end

    event :discard do
      # before :notify_discarded
      after :destroy
      transitions from: %i[initialized submitted approved rejected discarded finished_one approved_one], to: :discarded
    end
  end

  after_create do
    update_history(false)
  end

  before_destroy do
    product_data_change_requests.find_each(&:discard!)
  end

  has_many   :product_data_change_requests, as: :parent
  belongs_to :price_planning

  def product_requests_by_country(country, price_planning)
    product_data_change_requests
      .where(
        id: country.get_product_data_change_requests(price_planning).ids
      )
      .not_finished
  end

  def reject_country_data_change_request
    return if parent&.rejected?

    parent.history_options = history_options
    parent.reject!
  end

  def review_product_data_change_requests
    product_data_change_requests.not_skipped.each(&:review)
  end

  def unreview_product_data_change_requests
    product_data_change_requests.not_skipped.each(&:unreview)
  end

  def set_name
    self.name = "#{changeable.name} price change"
  end

  def responder
    initiator
  end

  def country
    parent.changeable
  end

  def notified_users
    parent.changeable.users.with_role(%w[brand_manager area_sales_manager head_of_marketing distribution_manager
                                          marketing_analyst]) + User.gpo
  end

  def next_approve_step(user)
    return :approve! if user.has_role?('head_of_marketing')

    if submitted?
      :approve_one!
    elsif approved_one?
      :approve_two!
    elsif approved_two?
      :approve!
    end
  end

  def approve_steps
    country_ids = product_data_change_requests.take
                                              .changeable
                                              .get_countries.ids
    users = User.includes(:countries).where(countries: { id: country_ids })

    distribution_managers = users.with_role(%w[distribution_manager]).any?
    marketing_analysts = users.with_role(%w[marketing_analyst]).any?

    if distribution_managers && marketing_analysts
      3
    elsif !distribution_managers && !marketing_analysts
      1
    else
      2
    end
  end

  def approved_state?
    approved_one? || approved_two? || approved? || submitted?
  end

  def unique_data_period
    requests = DataChangeRequest.where(changeable: changeable, parent: parent).not_finished.where(
      '(valid_from >= :from AND valid_from <= :until) OR ' \
      '(valid_until >= :from AND valid_until <= :until) OR ' \
      '(valid_from <= :from AND valid_until >= :until)',
      from: valid_from, until: valid_until
    ).where.not(id: id)

    if requests.present?
      errors.add(:time_period, 'Request already exists')
      return false
    end

    true
  end

  def finish_price_planning
    product_data_change_requests.each do |pdcr|
      pdcr.history_options = history_options
      pdcr.finish!
    end
  end

  def type_specific_email_attributes
    {
      country_id: parent.changeable.id
    }
  end

  def periodical_data(with_history = true)
    return JSON.parse(history_data) if finished? && history_data.present? && with_history

    pdcrs = product_data_change_requests.not_skipped
                                        .sort_by { |pdcr| pdcr.changeable.gpms_name }
                                        .group_by(&:changeable_id)
    pdcrs.each_with_object([]) do |(k,v), arr|
      arr << ProfitCenterVariant.find(k).periodical_data(v.sort_by(&:valid_from), parent.changeable)
    end
  end
end
