# frozen_string_literal: true

class BaseForm
  include ActiveModel::Model

  attr_accessor :record, :params

  REQUIRED_ATTRIBUTES = [].freeze

  def initialize(params, record: nil)
    @params = params
    @record = record

    # Line: 54
    parse_datetime_params

    # Slice all attributes which is not required by form
    # to omit save of unpredictable params
    @params.slice!(*permitted_attributes) # if permitted_attributes.present?

    # automatically validates all REQUIRED_ATTRIBUTES
    self.class.class_eval do
      validates(*self::REQUIRED_ATTRIBUTES, presence: true) if self::REQUIRED_ATTRIBUTES.present?
    end

    super(@params)
  end

  def boolean?(field)
    [TrueClass, FalseClass].include?(field.class)
  end

  def permitted_attributes
    self.class::PERMITTED_ATTRIBUTES
  end

  def collect_errors
    nested_errors = try(:nested_forms)&.map { |nf| nf&.errors&.messages }&.compact&.uniq.try(:[], 0)
    nested_errors = nested_errors.presence || {}
    errors.to_hash.merge!(nested_errors)
  end

  def sync_errors_to_form
    sync_errors(from: record, to: self)
  end

  def sync_errors_to_record
    sync_errors
  end

  def validate_nested(*nested_forms)
    nested_forms.map(&:valid?).all? || sync_nested_errors(nested_forms)
  end

  def sync_nested_errors(nested_forms)
    nested_forms.each do |n_form|
      n_form.errors.each do |code, text|
        errors.add("#{self.class.name.underscore.split('/').last}.#{code}", text)
      end
    end

    false
  end

  # uses datetime_params to fix the following issue:
  # https://stackoverflow.com/questions/5073756/where-is-the-rails-method-that-converts-data-from-datetime-select-into-a-datet
  def parse_datetime_params
    datetime_params.each do |param|
      next if @params[param].present?

      # set datetime to nil if year is blank
      if @params["#{param}(1i)"].blank?
        @params[param] = nil

        next
      end

      @params[param] = DateTime.new(*(1..5).map { |i| @params["#{param}(#{i}i)"].to_i })
    end
  rescue ArgumentError
    nil
  end

  # list datetime_params in child form in order to parse datetime properly
  def datetime_params
    []
  end

  def positive_numeric_validates(field, sym)
    return if field.blank? || (field.is_a?(Numeric) && !field.negative?)

    errors.add(sym, 'Must be a positive number')
  end

  def sync_errors(from: self, to: record)
    return if [from, to].any?(&:blank?)

    errors = from.errors.instance_variable_get('@errors')
    errors.push(to.errors.instance_variable_get('@errors'))  
    to.errors.instance_variable_set('@errors', errors.flatten.uniq)
  end
end
