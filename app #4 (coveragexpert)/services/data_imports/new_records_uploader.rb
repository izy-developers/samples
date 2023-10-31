# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/AbcSize
module DataImports
  class NewRecordsUploader < Base
    private

    def headers
      super.merge(attachment_link: 'Direct links AWS S3')
    end

    def init_company_group(row)
      c_group = CompanyGroup.find_or_create_by(code: row[:company_group_code]) do |cg|
        cg.name = row[:company_group_name]
      end

      unless c_group
        log_error(row, :company_group, row[:company_group_code])
        return false
      end

      c_group
    end

    def init_company(company_group, row)
      company = Company.find_or_create_by(naic_code: row[:company_naic_code]) do |c|
        c.name = row[:company_name]
        c.company_group_id = company_group.id
      end

      unless company
        log_error(row, :company, row[:company_naic_code])
        return false
      end

      company
    end

    def init_product(company, row)
      date_submitted = strfdate(row[:product_date_submitted])
      product = Product.find_by(id_num: row[:product_id_num].to_i)

      if product
        log_error(row, :product_id_num, row[:product_id_num])
        log_error(row, :product, +'Already exists')
      else
        product = Product.find_or_create_by(id_num: row[:product_id_num].to_i) do |prod|
          prod.serff_tracking_number = row[:serff_tracking_number]
          prod.date_submitted = date_submitted
          prod.name = row[:product_name]
          prod.insurance_type = row[:product_insurance_type]
          prod.in_scope = row[:product_in_scope]
          prod.line = row[:product_line]
          prod.general_type = row[:product_general_type]
          prod.doc_type = row[:product_doc_type]
          prod.version = row[:product_version]
          prod.note = econding_fixed(row[:product_note])
          prod.new_name = row[:product_new_name]
          prod.data_type = :owner
          prod.companies << company
        end

        unless product
          log_error(row, :product_id_num, row[:product_id_num])
          log_error(row, :product, +'Not created')
          return false
        end
      end

      product
    rescue ArgumentError
      log_error(row, :date_submitted, row[:product_date_submitted])
      log_error(row, :product, +'Not created')
    end

    def init_attachment_type(row)
      AttachmentType.find_or_create_by(name: row[:attachment_type_name])
    end

    def init_attachment(product, attachment_type, row)
      issue_date = strfdate(row[:attachment_issue_date])

      attachment = product.attachments.first

      if attachment
        log_error(row, :attachment, row[:attachment_document_name])
        log_error(row, :attachment, +'Already exists')
      else
        file_name = init_file(row[:file_name])

        unless file_name
          log_error(row, :file, row[:file_name])
          log_error(row, :file, +'Not created')
          return false
        end

        attachment = product.attachments.find_or_create_by(
          number_action: row[:attachment_number_action]
        ) do |attach|
          attach.document_name = econding_fixed(row[:attachment_document_name])
          attach.number_action = row[:attachment_number_action]
          attach.base_file_name = row[:attachment_base_file_name]
          attach.product_id = product.id
          attach.attachment_type_id = attachment_type.id
          attach.link = row[:attachment_link]
          attach.description_of_form = econding_fixed(row[:attachment_description_of_form])
          attach.optionality = row[:attachment_optionality]
          attach.effect = row[:attachment_effect]
          attach.impact = row[:attachment_impact]
          attach.complete_form_number = row[:attachment_complete_form_number]
          attach.issue_date = issue_date
          attach.file_name = file_name
          attach.skip_worker = true
        end

        unless attachment
          log_error(row, :attachment, row[:attachment_document_name])
          log_error(row, :attachment, +'Not created')
          return false
        end
      end

      attachment
    rescue ArgumentError => e
      log_error(row, :argument, +e.message)
      log_error(row, :attachment, +'Not created')
    end

    def init_file(file_name)
      manager = Managers::DirectoryManager.new(file_name)
      manager.create_dirs
      AwsS3::FileDownloader.new(file_name, file_name, manager.normalized_pdf_path, @bucket_name).perform
      MiniMagick::Image.open(manager.tmp_dir.join(file_name))
    end

    def init_attachment_pages(attachment)
      return if attachment.blank?

      ExtractPagesWorker.perform_async(attachment.id, true)
    end

    def init_business_classes(product, row)
      [row[:business_class_name1], row[:business_class_name2]].each do |business_class_name|
        init_business_class(product, business_class_name)
      end
    end

    def init_business_class(product, business_class_name)
      return unless none_zero(business_class_name)

      business_class = BusinessClass.find_or_create_by(name: capitalize_string(business_class_name))
      business_class.products << product if none_product(business_class, product.id)
    end

    def init_lob_tags(product, row)
      log_tags(row).each do |tag|
        next unless none_zero(tag[:name])

        if tag[:name].length > 12
          log_error(row, :lob_tag, +"Tag is too long #{tag[:name]}")
          next
        end

        lob_tag = LobTag.find_or_create_by(tag: tag[:name], filter: tag[:filter])

        next unless lob_tag

        lob_tag.products << product if none_product(lob_tag, product.id)
      end
    end

    def init_insurance_subtype(row)
      if none_zero(row[:insurance_subtype_name])
        subtype_name = capitalize_string(row[:insurance_subtype_name])
        InsuranceSubtype.find_or_create_by(name: subtype_name)
      end

      return unless none_zero(row[:insurance_subtype_name2])

      subtype_name2 = capitalize_string(row[:insurance_subtype_name2])
      InsuranceSubtype.find_or_create_by(name: subtype_name2) if subtype_name && subtype_name != subtype_name2
    end

    def init_filing_type(product, row)
      if none_zero(row[:filing_type_name])
        filing_type = FilingType.find_or_create_by(name: capitalize_string(row[:filing_type_name]))
        filing_type.products << product if none_product(filing_type, product.id)
      end

      return unless none_zero(row[:filing_type_name2])

      name2 = capitalize_string(row[:filing_type_name2])
      filing_type = FilingType.find_or_create_by(name: name2) if filing_type && filing_type != name2
      filing_type.products << product if none_product(filing_type, product.id)
    end

    def init_concerns(product, row)
      return if row[:concerns].blank?

      row[:concerns].split(',').each do |concern|
        next unless none_zero(concern)

        concern = Concern.find_or_create_by(name: concern)
        concern.products << product if none_product(concern, product.id)
      end
    end
  end
end
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/ClassLength
