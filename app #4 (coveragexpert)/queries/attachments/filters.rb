# frozen_string_literal: true

module Attachments
  module Filters
    def filters
      {
        products_new_name: products_data,
        sub_type_tags: tags_data['Sub-Type'],
        form_type_tags: tags_data['Form-Type'],
        type_tags: tags_data['Type'],
        group_names: group_names,
        company_names: companies_data[0]&.sort,
        business_class_names: business_class_names
      }
    end

    def products_data
      @products_data ||= fetch_products_data
    end

    def tags_data
      @tags_data ||= fetch_lob_tags.each_with_object(Hash.new { |h, k| h[k] = [] }) do |value, hash|
        hash[value.filter] << value
      end
    end

    def companies_data
      @companies_data ||= fetch_companies_data
    end

    def group_names
      @group_names ||= fetch_group_names
    end

    def business_class_names
      @business_class_names ||= fetch_business_class_names
    end

    def lob_tags
      @lob_tags ||= fetch_lob_tags
    end

    private

    def fetch_products_data
      attachments.distinct.reorder('').pluck(:new_name).compact.sort
    end

    def fetch_tags_data
      lob_tags.each_with_object(Hash.new { |h, k| h[k] = [] }) do |value, hash|
        hash[value.filter] << value
      end
    end

    def fetch_companies_data
      Company
        .where(id:
          attachments.joins(product: :company_products).select('DISTINCT company_products.company_id AS company_id')
          .reorder(''))
        .pluck(:name, :company_group_id)
        .transpose
    end

    def fetch_group_names
      CompanyGroup.where(id: companies_data[1]).pluck(:name).sort
    end

    def fetch_business_class_names
      BusinessClass
        .joins(products: :attachments)
        .merge(attachments)
        .reorder('')
        .distinct.pluck(:name)
        .sort
    end

    def fetch_lob_tags
      LobTag
        .where(id:
          attachments
            .joins('LEFT JOIN "lob_tag_products" "ltp" ON "ltp"."product_id" = "products"."id"').reorder('')
            .select('DISTINCT ltp.lob_tag_id AS lob_tag_id'))
        .sort_by(&:short_detail)
    end
  end
end
