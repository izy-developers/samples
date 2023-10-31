# == Schema Information
#
# Table name: data_change_request_corrections
#
#  id                     :bigint           not null, primary key
#  status                 :string           default("initialized")
#  comment                :string
#  user_id                :bigint
#  data_change_request_id :bigint
#  valid_from             :datetime
#  valid_until            :datetime
#  values                 :json
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
class DataChangeRequestCorrection < ApplicationRecord
  attr_accessor :notify_responders_after_commit

  delegate :notify_responders, to: :data_change_request

  belongs_to :user
  belongs_to :data_change_request

  after_commit :notify_responders, if: :notify_responders_after_commit, on: [:create, :update]

  def as_info
    {
      user: user.as_info(true),
      valid_from: valid_from.to_date.to_s,
      valid_until: valid_until.to_date.to_s,
      created_at: created_at,
      status: status,
      values: values,
      comment: comment
    }
  end
end
