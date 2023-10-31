# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/AbcSize
module DataImports
  class Base
    def initialize(data_import)
      @data_import = data_import
      @document = @data_import.file_name.file.read
      @bucket_name = 'keydatabase'
      @event_service = DataImports::EventService.new(data_import.id)
      @log = {}
    end

    def perform
      @event_service.in_progress_status
      import
      @data_import.update(log: @log)
      @event_service.succeed_status
    rescue StandardError => e
      @data_import.update(log: @log.merge(custom_error: [+"#{e.class} - #{e.message}"]))
      @event_service.failed_status
    end

    private

    def headers
      {
        serff_tracking_number: 'SERFF Tracking Number',
        attachment_type_name: 'Attachments (Type)',
        attachment_document_name: 'Document Name',
        attachment_number_action: 'Number/Action',
        attachment_base_file_name: 'Attachments',
        product_date_submitted: 'Date Submitted',
        insurance_subtype_name: 'Sub Type of Insurance',
        insurance_subtype_name2: 'Sub Type of Insurance2',
        filing_type_name: 'Filing Type',
        product_name: 'Product Name',
        product_insurance_type: 'Type Of Insurance',
        product_in_scope: 'IN SCOPE',
        product_line: 'Line',
        product_general_type: 'General Type',
        product_doc_type: 'Doc Type',
        lob_tag_tag1: 'LOB_1',
        lob_tag_tag2: 'LOB_2',
        lob_tag_tag3: 'LOB_3',
        product_version: 'VERSION',
        business_class_name1: 'BUSINESS_CLASS_1',
        business_class_name2: 'BUSINESS_CLASS_2',
        product_note: 'NOTE',
        product_new_name: 'NEW PRODUCT NAME',
        company_naic_code: 'CO_CODE',
        company_name: 'CO_NAME',
        company_group_code: 'GRP_CODE',
        company_group_name: 'GRP_NAME',
        attachment_link: 'LINK',
        attachment_description_of_form: 'Description of Form',
        attachment_optionality: 'Mandatory Optional',
        attachment_effect: 'Effect',
        attachment_impact: 'Rate or Premium Impact',
        attachment_complete_form_number: 'Completed Form Num',
        attachment_issue_date: 'Issue Date',
        product_id_num: 'ID NUM',
        file_name: 'Downloaded File Name'
      }
    end

    def import
      csv_map.each { |row| import_row(row) }
    end

    def import_row(row)
      ActiveRecord::Base.transaction do
        strip_row(row)
        company_group = init_company_group(row)
        company = init_company(company_group, row)
        product = init_product(company, row)
        return unless product.is_a?(Product)

        attachment_type = init_attachment_type(row)
        init_business_classes(product, row)
        init_lob_tags(product, row)
        init_insurance_subtype(row) if @data_import.Upload_import_type?
        init_filing_type(product, row) if @data_import.Upload_import_type?
        init_concerns(product, row)
        attachment = init_attachment(product, attachment_type, row)
        init_attachment_pages(attachment) if @data_import.Upload_import_type?
      end
    end

    def csv_map
      result = []
      CSV.parse(@document, headers: true).each do |row|
        row_hash = headers.each_with_object({}) do |(k, v), obj|
          obj[k] = row[v]
          obj
        end
        result << row_hash
      end
      result
    end

    def none_zero(val)
      val.present? && val != '0'
    end

    def strip_row(row)
      row.update(row) { |_, v| v&.strip }
    end

    def capitalize_string(val)
      return '' if val.blank?

      val.chomp.split(/\b/).map(&:capitalize).join
    end

    def log_error(row, obj, key)
      econding_fixed(key)

      @log[row[:product_id_num]] ||= []
      @log[row[:product_id_num]] << "#{obj} - #{key}"
    end

    def econding_fixed(val)
      return '' if val.blank?

      val.delete!("^\u{0000}-\u{007F}")
      val
    end

    def log_tags(row)
      [
        { name: row[:lob_tag_tag1], filter: 'Sub-Type' },
        { name: row[:lob_tag_tag2], filter: 'Sub-Type' },
        { name: row[:lob_tag_tag3], filter: 'Sub-Type' },
        { name: row[:product_general_type], filter: 'Type' },
        { name: row[:product_doc_type], filter: 'Form-Type' }
      ]
    end

    def none_product(obj, product_id)
      obj && !obj.product_ids.include?(product_id)
    end

    def strfdate(val)
      return '' if val.blank?

      Time.zone.parse(Date.strptime(val.tr('-', '/'), '%m/%d/%Y').to_s)
    end
  end
end
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/ClassLength
