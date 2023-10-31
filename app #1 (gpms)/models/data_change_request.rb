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
class DataChangeRequest < ApplicationRecord
  include AASM
  include AfterCommitEverywhere
  include ValidTimeModel
  include Attachable

  attr_accessor :history_options

  validate :unique_data_period
  validate :valid_period, on: :create
  validates :valid_from, :valid_until, :initiator, presence: true

  belongs_to :initiator, class_name: 'User', foreign_key: :initiator_id
  belongs_to :changeable, polymorphic: true
  belongs_to :parent, polymorphic: true, required: false

  has_many :data_change_request_corrections, dependent: :destroy
  has_many :comments, as: :commentable

  before_create :set_name

  scope :not_finished, -> { where.not(status: %w[finished discarded uploaded]) }
  scope :not_approved, -> { where(status: %w[initialized rejected approved_one approved_two]) }
  scope :reviewed, -> { where(reviewed: true) }
  scope :not_reviewed, -> { where(reviewed: false) }
  scope :skipped, -> { where(skip_review: true) }
  scope :not_skipped, -> { where(skip_review: false) }
  scope :for, ->(r) { where(changeable: r) }
  scope :period, ->(from, to) do
    where('valid_until >= ? AND valid_from <= ?',
      Time.zone.parse(from), Time.zone.parse(to).end_of_month)
  end

  def self.accessible_for(user)
    if user.mob_role? || user.has_role?('gpo') || user.has_role?('admin') || user.has_role?('cfo')
      where(type: %w[CurrencyDataChangeRequest CountryDataChangeRequest BrandDataChangeRequest ProductDataChangeRequest])
    else
      where.not(type: 'CurrencyDataChangeRequest')
    end
  end

  def self.as_info
    self.find_each.map(&:as_info)
  end

  def as_info(limited = false)
    result = self.attributes.merge(
      valid_from: valid_from.to_date.to_s,
      valid_until: valid_until.to_date.to_s,

      initiator: initiator.account_type_humanize,
      field_name: field_name,
      responder: responder&.full_name
    )

    result.merge!(corrections_info)
    result.merge!(
      object: changeable.name,
      object_id: changeable.id,
      object_name: changeable.short_name || changeable.name || '',
      comments: Comment.for_commentable(self.class.to_s, 'price_planning', id).order('created_at DESC').map(&:as_info),
    ) if !limited

    result
  end

  def for_index
    {
      id: id,
      type: type,
      object: changeable.is_a?(ProfitCenterVariant) ? changeable.gpms_name : changeable.name,
      status: status,
      created_by: initiator.roles.pluck(:account_type).sort.uniq.join(', '),
      created_by_name: initiator.full_name,
      valid_from: valid_from.to_date.to_s,
      valid_until: valid_until.to_date.to_s,
      approved: approved? ? updated_at.to_date.to_s : '',
      last_modified: updated_at.to_date.to_s
    }
  end

  def filtered_comments
    Comment.for_commentable(self.class.to_s, 'price_planning', id).order('created_at DESC').map(&:as_info)
  end

  def corrections
    data_change_request_corrections.order('created_at DESC')
  end

  def corrections_info
    corr = corrections

    return {} unless corr.any?

    {
      last_modified: corr[0].created_at.to_date.to_s,
      last_correction: corr[0].values[field].to_f,
      corrections: corr.map(&:as_info)
    }
  end

  def last_modified
    self.data_change_request_corrections.order('created_at DESC').first.created_at.to_date.to_s
  end

  def update_changeable
    changeable.update_from_change_request(self)
  end

  def upload_rates
    UploadHistoricRatesJob.perform_later(data_change_request_id: id)
  end

  def update_history(with_email = true)
    return unless history_options

    comment = history_options[:comment]
    user = history_options[:user]
    options = history_options.except(:comment, :user)

    if update!(options)
      correction = data_change_request_corrections.new(
        user_id: user.id,
        status: status,
        valid_from: valid_from.beginning_of_month,
        valid_until: valid_until.end_of_month,
        values: values,
        comment: comment
      )
      correction.notify_responders_after_commit = with_email
      correction.save!
    end
  end

  def review
    update!(reviewed: true)
  end

  def unreview
    update!(reviewed: false)
  end

  def set_name
    self.name = "#{self.changeable_type} #{field_name} update request"
  end

  def notify_discarded
    disc_notified_users = notified_users || (User.gpo + User.admin)
    self.status = 'discarded'

    Email.create(
      recipient_emails: disc_notified_users.map(&:email).uniq,
      template_name: 'notify_responders',
      mailer_class: "#{self.class.name}Mailer",
      email_attrs: common_email_attributes.merge(
        correction_user: history_options[:user].attributes.symbolize_keys.slice(:first_name, :last_name)
      )
    )
  end

  def notify_responders
    Email.create(
      recipient_emails: notified_users.map(&:email),
      template_name: 'notify_responders',
      mailer_class: "#{self.class.name}Mailer",
      email_attrs: common_email_attributes.merge(type_specific_email_attributes)
    ) if notified_users
  end

  def type_specific_email_attributes
    {}
  end

  def common_email_attributes
    correction = data_change_request_corrections.last
    {
      data_change_request: serializable_hash,
      object: changeable.serializable_hash,
      correction_user: correction.user.serializable_hash(only: %w(first_name last_name))
    }
  end

  def notified_users
    User.with_role('gpo')
  end

  def field_name
    case field
    when 'exch_fixed'
      'LE exchange rate'
    when 'exch_bu'
      'BU exchange rate'
    else
      field
    end
  end

  def update_dates_from_pdcr
    return if finished?

    new_valid_from = product_data_change_requests.not_finished.not_skipped.pluck(:valid_from).min
    new_valid_until = product_data_change_requests.not_finished.not_skipped.pluck(:valid_until).max
    update(
      valid_from: new_valid_from,
      valid_until: new_valid_until
    ) if new_valid_from && new_valid_until
  end

  private

  def responder
    (self.data_change_request_corrections.last.user.mob_role? && changeable.cfo) ? changeable.cfo : User.mob.take
  end

  def valid_period
    if !skip_review && valid_from && valid_from <= Time.zone.now.end_of_month
      errors.add(:valid_from, 'Wrong time period')
      return false
    end

    true
  end

  def unique_data_period
    requests = DataChangeRequest.where(changeable: changeable).not_finished.where(
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

  def invalidate_existing
    true
  end

  def historize_data
    update(history_data: periodical_data(false).to_json)
  end
end
