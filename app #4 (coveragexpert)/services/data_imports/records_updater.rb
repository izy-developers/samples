# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/MethodLength
module DataImports
  class RecordsUpdater < Base
    private

    def init_company_group(row)
      company_group = CompanyGroup.find_by(code: row[:company_group_code])

      unless company_group
        log_error(row, :company_group, row[:company_group_code])
        return false
      end

      company_group.update(name: row[:company_group_name])
      company_group
    end

    def init_company(company_group, row)
      company = Company.find_by(naic_code: row[:company_naic_code])
      unless company
        log_error(row, :company, row[:company_naic_code])
        return false
      end

      company.update(
        name: row[:company_name],
        company_group_id: company_group.id
      )
      company
    end

    def init_product(company, row)
      product = Product.find_by(id_num: row[:product_id_num].to_i)

      unless product
        log_error(row, :product_id_num, row[:product_id_num])
        return false
      end

      update_product(product, company, row)

      product
    end

    def update_product(product, company, row)
      product.update!(
        in_scope: row[:product_in_scope],
        line: row[:product_line],
        general_type: row[:product_general_type],
        doc_type: row[:product_doc_type],
        version: row[:product_version],
        note: econding_fixed(row[:product_note]),
        new_name: row[:product_new_name]
      )
      product.companies << company unless product.company_ids.include?(company.id)
    rescue StandardError
      log_error(row, :product, +'Not updated')
    end

    def init_attachment_type(row)
      AttachmentType.find_by(name: capitalize_string(row[:attachment_type_name]))
    end

    def init_attachment(product, attachment_type, row)
      attachment = product.attachments.find_by(
        number_action: row[:attachment_number_action]
      )

      unless attachment
        log_error(row, :attachment, row[:attachment_document_name])
        return false
      end

      update_attachment(attachment, attachment_type, row)
    end

    # rubocop:disable Metrics/AbcSize
    def update_attachment(attachment, attachment_type, row)
      issue_date = strfdate(row[:attachment_issue_date])

      attachment.update!(
        document_name: econding_fixed(row[:attachment_document_name]),
        base_file_name: row[:attachment_base_file_name],
        attachment_type_id: attachment_type.id,
        link: row[:attachment_link],
        description_of_form: econding_fixed(row[:attachment_description_of_form]),
        optionality: row[:attachment_optionality],
        effect: row[:attachment_effect],
        impact: row[:attachment_impact],
        complete_form_number: row[:attachment_complete_form_number],
        issue_date: issue_date,
        skip_worker: true
      )
    rescue ArgumentError
      log_error(row, :issue_date, row[:attachment_issue_date])
      log_error(row, :attachment, +'Not updated')
    end
    # rubocop:enable Metrics/AbcSize

    def init_business_classes(product, row)
      [row[:business_class_name1], row[:business_class_name2]].each do |business_class_name|
        init_business_class(row, product, business_class_name)
      end
    end

    def init_business_class(row, product, business_class_name)
      return unless none_zero(business_class_name)

      business_class = BusinessClass.find_by(name: capitalize_string(business_class_name))
      log_error(row, :business_class, business_class_name) unless business_class

      business_class.products << product if none_product(business_class, product.id)
    end

    # rubocop:disable Metrics/AbcSize
    def init_lob_tags(product, row)
      log_tags(row).each do |tag|
        next unless none_zero(tag[:name])

        if tag[:name].length > 12
          log_error(row, :lob_tag, +"Tag is too long: #{tag[:name]}")
          next
        end

        lob_tag = LobTag.find_by(tag: tag[:name], filter: tag[:filter])

        unless lob_tag
          log_error(row, :lob_tag, +"#{tag[:name]} #{tag[:filter]}")
          next
        end

        lob_tag.products << product if none_product(lob_tag, product.id)
      end
    end
    # rubocop:enable Metrics/AbcSize

    def init_concerns(product, row)
      return if row[:concerns].blank?

      row[:concerns].split(',').each do |concern|
        next if concern.blank?

        concern = Concern.find_by(name: concern)
        unless concern
          log_error(row, :concern, concern)
          next
        end

        concern.products << product if none_product(concern, product.id)
      end
    end
  end
end
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/ClassLength
