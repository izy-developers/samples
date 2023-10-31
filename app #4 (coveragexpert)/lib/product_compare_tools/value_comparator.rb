# frozen_string_literal: true

module ProductCompareTools
  class ValueComparator
    MATCH_STATUSES = {
      none: '-',
      change: 'Change',
      increase: 'Increase',
      decrease: 'Decrease',
      new: 'New',
      match: 'Match',
      missing: 'Missing'
    }.freeze

    def initialize(first_product_value, second_product_value, key:)
      @first_product_value = first_product_value
      @second_product_value = second_product_value
      @key = key
    end

    def compare
      comparator = case @key
                   when 'policy_number'
                     proc { none }
                   when 'named_organization', 'address', 'claim_notice', 'policy_form_number'
                     proc { text }
                   when 'prior_litigation_date', 'policy_period_from', 'policy_period_to'
                     proc { date }
                   when 'limit_of_liability', 'retention', 'policy_premium',
      'extended_reporting_period'
                     proc { number }
                   when 'endorsement_form_numbers'
                     proc { array }
                   else
                     proc { text }
                   end

      comparator.call
    end

    def none
      MATCH_STATUSES[:none]
    end

    def text
      if @first_product_value && @second_product_value.blank?
        MATCH_STATUSES[:missing]
      elsif @first_product_value.blank? && @second_product_value
        MATCH_STATUSES[:new]
      elsif @first_product_value == @second_product_value
        MATCH_STATUSES[:match]
      elsif @first_product_value != @second_product_value
        MATCH_STATUSES[:change]
      end
    end

    def date
      first_product_date = Date.strptime(@first_product_value, '%m/%d%/%Y')
      second_product_date = Date.strptime(@second_product_value, '%m/%d%/%Y')

      if first_product_date > second_product_date
        MATCH_STATUSES[:decrease]
      elsif first_product_date < second_product_date
        MATCH_STATUSES[:increase]
      else
        MATCH_STATUSES[:match]
      end
    rescue Date::Error
      if @first_product_value > @second_product_value
        MATCH_STATUSES[:decrease]
      elsif @first_product_value < @second_product_value
        MATCH_STATUSES[:increase]
      else
        MATCH_STATUSES[:match]
      end
    end

    def number
      first_product_number = @first_product_value.scan(/\d+/).join.to_i
      second_product_number = @second_product_value.scan(/\d+/).join.to_i

      if first_product_number > second_product_number
        MATCH_STATUSES[:decrease]
      elsif first_product_number < second_product_number
        MATCH_STATUSES[:increase]
      else
        MATCH_STATUSES[:match]
      end
    end

    def array
      first_result = @first_product_value.each_with_object([]) do |value, result|
        result << if @second_product_value.include?(value)
                    [
                      value, value, MATCH_STATUSES[:match]
                    ]
                  else
                    [
                      value, '', MATCH_STATUSES[:missing]
                    ]
                  end
      end

      second_result = @second_product_value.each_with_object([]) do |value, result|
        next if @first_product_value.include?(value)

        result << [
          '', value, MATCH_STATUSES[:new]
        ]
      end

      [*first_result, *second_result]
    end
  end
end
