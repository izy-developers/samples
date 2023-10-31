# frozen_string_literal: true

#  first_pdf_file  :string
#  second_pdf_file :string

ActiveAdmin.register ProductCompareTool, as: 'Compare Tool' do
  first_pdf_file_desc = 'First PDF File'
  second_pdf_file_desc = 'Second PDF File'
  # first_pdf_link_desc = 'First PDF File Link'
  # second_pdf_link_desc = 'Second PDF File Link'
  # confirm_desc = 'Are you certain you want to delete this?'

  menu label: 'Compare Tool', priority: 2

  permit_params :first_pdf_file, :second_pdf_file,
                :first_product_id, :second_product_id

  config.clear_action_items!

  action_item only: :show do
    link_to 'Compare documents', '', id: 'comparing_documents_button' unless params[:id].nil?
  end

  controller do
    before_action { @page_title = 'Compare Tool' }

    def scoped_collection
      return super if params['action'] == 'show'

      super.where(first_product_id: Product.where(data_type: :compare_tool),
                  second_product_id: Product.where(data_type: :compare_tool))
    end

    def create
      params[:product_compare_tool][:first_product_id] = Product.create(data_type: :compare_tool).id
      params[:product_compare_tool][:second_product_id] = Product.create(data_type: :compare_tool).id

      Attachment.create(
        product_id: params[:product_compare_tool][:first_product_id],
        file_name: params[:product_compare_tool][:first_pdf_file],
        skip_worker: true
      )
      Attachment.create(
        product_id: params[:product_compare_tool][:second_product_id],
        file_name: params[:product_compare_tool][:second_pdf_file],
        skip_worker: true
      )

      create!
    end
  end

  action_item only: :index do
    link_to 'New Comparison', new_admin_compare_tool_path, class: 'create-compare-pdf'
  end

  config.filters = false

  index do
    selectable_column
    column first_pdf_file_desc do |product_compare_tool|
      link_to product_compare_tool.first_pdf_file.file.filename, product_compare_tool.first_pdf_file.url
    end
    column second_pdf_file_desc do |product_compare_tool|
      link_to product_compare_tool.second_pdf_file.file.filename, product_compare_tool.second_pdf_file.url
    end
    actions
  end

  show do
    attributes_table do
      row(first_pdf_file_desc) { link_to resource.first_pdf_file.file.filename, resource.first_pdf_file.url }
      row(second_pdf_file_desc) { link_to resource.second_pdf_file.file.filename, resource.second_pdf_file.url }
    end
  end

  form do |f|
    f.inputs 'Compared PDF Files' do
      f.input :first_pdf_file, as: :file, label: 'First PDF File'
      f.input :second_pdf_file, as: :file, label: 'Second PDF File'
    end

    f.actions
  end
end
