# frozen_string_literal: true

ActiveAdmin.register Attachment, as: 'Dashboard' do
  menu label: 'Dashboard', priority: 1

  permit_params :file_name, :submission_date, :attachment_type,
                product_attributes: %i[id serff_tracking_number date_filled
                                       filing_status_id state description_of_form
                                       disposition_date state_status
                                       state_status_last_changed address phone
                                       optionality impact restriction disposition_status
                                       filling_type_id insurance_subtype_id
                                       insurance_product_id insurance_type serff_status
                                       form_type data_type]

  config.filters = false
  config.batch_actions = false
  config.clear_action_items!

  action_item only: :index do
    link_to 'Upload New Document', new_admin_dashboard_path, id: 'upload_new_document'
  end

  controller do
    def scoped_collection
      return super if params['action'] == 'show'

      super.includes(:product).where(product: Product.where(data_type: :dashboard))
    end

    def create
      params[:attachment][:product_attributes] = { data_type: :dashboard }
      create!
    end
  end

  index do
    column('Sub-type of Insurance') do |attachment|
      product = DashboardProductLookupSevice.new(attachment).perform
      product.try(:insurance_subtype).try(:name) || 'N/A'
    end

    column('Policy #') do |attachment|
      attachment.try(:product).try(:parsed)&.fetch('declaration', nil)&.fetch('policy_number', nil)
    end

    column('Named Organization') do |attachment|
      attachment.try(:product).try(:parsed)&.fetch('declaration', nil)&.fetch('named_organization', nil)
    end

    column('Policy Period To') do |attachment|
      attachment.try(:product).try(:parsed)&.fetch('declaration', nil)&.fetch('policy_period', nil)&.fetch('to', nil)
    end

    column('Limit of Liability') do |attachment|
      attachment.try(:product).try(:parsed)&.fetch('declaration', nil)&.fetch('limit_of_liability', nil)
    end

    column('Retention') do |attachment|
      attachment.try(:product).try(:parsed)&.fetch('declaration', nil)&.fetch('retention', nil)
    end

    column('Policy Premium') do |attachment|
      attachment.try(:product).try(:parsed)&.fetch('declaration', nil)&.fetch('policy_premium', nil)
    end

    column('Claim Notice') do |attachment|
      attachment.try(:product).try(:parsed)&.fetch('declaration', nil)&.fetch('claim_notice', nil)
    end

    actions
  end

  form do |f|
    f.inputs 'Product', for: [:product, resource.product] do |p|
      p.input :completed_form_number, label: 'Completed Form #'
      p.input :form_type
      p.input :optionality, label: 'Mandatory or Optional'
      p.input :restriction, label: 'Restricts, Broadens or Other'
      p.input :impact, label: 'Rate or Premium Impact'
      p.input :description_of_form, as: :string
    end

    f.inputs 'Attachment' do
      f.input :file_name, label: 'Attachment', as: :file
    end

    f.actions
  end

  show do
    attributes_table do
      row('Attachments') do
        link_to 'Attachment link', resource.try(:file_name).try(:url)
      end
      row('Complete Form #') { resource.complete_form_number }
      row :form_type
      row('Mandatory or Optional') { resource.optionality }
      row('Restricts, Broadens or Other') { resource.restriction }
      row('Rate or Premium Impact') { resource.impact }
      row :description_of_form
    end
  end
end
