# frozen_string_literal: true

# == Schema Information
#
# Table name: attachments
#
#  id                   :bigint           not null, primary key
#  file_name            :string
#  attachment_type_id   :bigint
#  product_id           :bigint
#  submission_date      :datetime
#  document_name        :string
#  number_action        :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  skip_worker          :boolean
#  optionality          :integer
#  impact               :integer
#  restriction          :integer
#  form_type            :string
#  complete_form_number :string
#  form_number          :string
#  date_filed           :date
#  description_of_form  :text
#  form_title           :string
#  linked               :boolean
#  base_file_name       :string
#  old_effect           :string
#  link                 :string
#  issue_date           :date
#  effect               :integer
#
class Attachment < ApplicationRecord
  belongs_to :attachment_type, optional: true
  belongs_to :product, optional: true
  has_many :lob_tags, through: :product
  has_many :companies, through: :product
  has_many :saved_attachments, dependent: :destroy
  has_many :users_saved, through: :saved_attachments, source: :user
  has_many :attachment_pages, dependent: :destroy
  delegate :group, to: :product

  enum optionality: { Optional: 0, Mandatory: 1, "UNDER_REVIEW": 2 }, _suffix: true
  enum impact: { Yes: 0, No: 1, "N/A": 2, "UNDER_REVIEW": 3 }, _suffix: true
  enum effect: { 'Restricts Coverage': 0, 'Clarifies Coverage': 1, 'Broadens Coverage': 2,
                 'N/A': 3, 'Broadens & Restricts Coverage': 4, 'Other': 5, 'UNDER_REVIEW': 6 }, _suffix: true

  mount_uploader :file_name, AttachmentUploader
  accepts_nested_attributes_for :product

  after_save :perform_attachment, if: :saved_change_to_file_name?

  scope :saved_by, ->(user) { joins(:saved_attachments).where(saved_attachments: { user_id: user.id }) }
  scope :by_lob_tag_id, ->(id) { joins(product: :lob_tag_products).where('lob_tag_products.lob_tag_id = ?', id) }

  # HACK: convert integer to use _cont predicate https://github.com/activerecord-hackery/ransack/wiki/Using-Ransackers
  ransacker :optionality do
    Arel.sql("to_char(optionality, '9999999')")
  end

  ransacker :impact do
    Arel.sql("to_char(impact, '9999999')")
  end

  ransacker :effect do
    Arel.sql("to_char(effect, '9999999')")
  end
  # HACK: end

  ransacker :purchased do |_|
    Arel.sql('saved_attachments.created_at')
  end

  ransacker :expiry_date do |_|
    Arel.sql('saved_attachments.created_at')
  end

  def perform_attachment
    return if skip_worker

    AttachmentWorker.perform_in(10.seconds, id, product_id)
    ExtractPagesWorker.perform_async(id, true)
  end
end
