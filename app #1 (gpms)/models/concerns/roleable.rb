# frozen_string_literal: true

module Roleable
  extend ActiveSupport::Concern

  ELEVATED_TYPES = %w[global_manager cfo mob admin].freeze

  # Roles used in Price Planning module
  PRODUCT_PRICE_REQUEST_ROLES = %w[admin brand_manager area_sales_manager].freeze
  BRAND_PRICE_REQUEST_ROLES = %w[admin head_of_marketing marketing_analyst distribution_manager].freeze
  COUNTRY_PRICE_REQUEST_ROLES = %w[admin country_head deputy_country_head gpo].freeze
  GLOBAL_PRICE_REQUEST_ROLES = %w[admin mob mob_gb mob_dep mob_gb_dep].freeze

  # Roles used to plan currency rates
  CURRENCY_RATES_FINISH_ROLES = %w[gpo mob_dep mob_gb_dep mob mob_gb cfo
                                   controlling_manager country_support_manager global_forecast_manager
                                   head_of_global_marketing country_head head_of_marketing].freeze

  RATES_RESPONSIBLE_ROLES = %w[
    mob_gb controlling_manager global_forecast_manager
    global_marketing_manager head_of_global_marketing
  ].freeze

  # Roles abbreviations
  ACCOUNT_TYPE_DEFINITIONS = {
    cfo: 'Chief Financial Officer',
    gpo: 'Global Pricing Officer',
    mob: 'Member of the Board-FI/CO/IT',
    mob_gb: 'Member of the Board-GB',
    mob_dep: 'MOB-FI-Deputy',
    mob_gb_dep: 'MOB-GB-Deputy',
    ceo: 'CEO'
  }.freeze

  ALL_ROLES = {
    Admin: 'admin',
    'Area Sales Manager': 'area_sales_manager',
    'Brand manager': 'brand_manager',
    CEO: 'ceo',
    'Chief Financial Officer': 'cfo',
    'Controlling Manager': 'controlling_manager',
    'Country Head': 'country_head',
    'Country Manager': 'country_manager',
    'Country Support Manager': 'country_support_manager',
    'Deputy Country Head': 'deputy_country_head',
    'Distribution Manager': 'distribution_manager',
    'Global Brand Manager': 'global_brand_manager',
    'Global Forecast Manager': 'global_forecast_manager',
    'Global Manager': 'global_manager',
    'Global Marketing Manager': 'global_marketing_manager',
    'Global Pricing Officer': 'gpo',
    'Head of Global Marketing': 'head_of_global_marketing',
    'Head of Marketing': 'head_of_marketing',
    'Marketing Analyst': 'marketing_analyst',
    'Member of the Board-GB': 'mob_gb',
    'Member of the Board-FI/CO/IT': 'mob',
    'MOB-GB-Deputy': 'mob_gb_dep',
    'MOB-FI-Deputy': 'mob_dep'
  }.freeze

  included do
    after_initialize :set_default_role, if: :new_record?

    scope :rates_responsible, -> { with_role(RATES_RESPONSIBLE_ROLES) }
    scope :country_head_role, -> { with_role(%w[country_head deputy_country_head]) }
    scope :mobs, -> { with_role(%w[mob mob_gb mob_dep mob_gb_dep]) }
    scope :country_manager, -> { with_role(%w[country_manager]) }
    scope :global_manager, -> { with_role(%w[global_manager]) }
    scope :admin, -> { with_role(%w[admin]) }
    scope :cfo, -> { with_role(%w[cfo]) }
    scope :mob, -> { with_role(%w[mob]) }
    scope :country_head, -> { with_role(%w[country_head]) }
    scope :gpo, -> { with_role(%w[gpo]) }
    scope :controlling_manager, -> { with_role(%w[controlling_manager]) }
    scope :global_forecast_manager, -> { with_role(%w[global_forecast_manager]) }
    scope :country_support_manager, -> { with_role(%w[country_support_manager]) }
    scope :head_of_marketing, -> { with_role(%w[head_of_marketing]) }
    scope :global_marketing_manager, -> { with_role(%w[global_marketing_manager]) }
    scope :distribution_manager, -> { with_role(%w[distribution_manager]) }
    scope :mob_gb, -> { with_role(%w[mob_gb]) }
    scope :mob_dep, -> { with_role(%w[mob_dep]) }
    scope :brand_manager, -> { with_role(%w[brand_manager]) }
    scope :ceo, -> { with_role(%w[ceo]) }
    scope :head_of_global_marketing, -> { with_role(%w[head_of_global_marketing]) }
    scope :area_sales_manager, -> { with_role(%w[area_sales_manager]) }
    scope :marketing_analyst, -> { with_role(%w[marketing_analyst]) }
    scope :global_brand_manager, -> { with_role(%w[global_brand_manager]) }
    scope :deputy_country_head, -> { with_role(%w[deputy_country_head]) }
    scope :mob_gb_dep, -> { with_role(%w[mob_gb_dep]) }
  end

  # Add a role: User.make_mob
  Roleable::ALL_ROLES.values.each do |role|
    define_method "make_#{role}" do
      roles << Role.find_by(account_type: role)
    end
  end

  # Removes a role: User.dismiss_mob
  Roleable::ALL_ROLES.values.each do |role|
    define_method "dismiss_#{role}" do
      roles.delete(Role.find_by(account_type: role))
    end
  end

  # Checks for role: User.mob?
  Roleable::ALL_ROLES.values.each do |role|
    define_method "#{role}?" do
      has_role?(role)
    end
  end

  def elevated?
    account_types.included_in?(ELEVATED_TYPES)
  end

  def has_admin_access?
    has_role?('admin') || has_role?('gpo')
  end

  def account_type_humanize
    account_type_definitions || humanize_roles
  end

  def account_type_definitions
    return nil unless account_type_symbolize.included_in?(ACCOUNT_TYPE_DEFINITIONS.keys)

    ACCOUNT_TYPE_DEFINITIONS.select { |key| account_type_symbolize.map(&:to_sym).include?(key) }.values
  end

  def humanize_roles
    account_types.map { |type| type.humanize.titleize }
  end

  def account_type_symbolize
    account_types.map(&:to_sym)
  end

  def product_pricing_responsible?
    account_types.included_in?(PRODUCT_PRICE_REQUEST_ROLES)
  end

  def brand_pricing_responsible?
    account_types.included_in?(BRAND_PRICE_REQUEST_ROLES)
  end

  def country_pricing_responsible?
    account_types.included_in?(COUNTRY_PRICE_REQUEST_ROLES)
  end

  def global_pricing_responsible?
    account_types.included_in?(GLOBAL_PRICE_REQUEST_ROLES)
  end

  def currency_change_responsible?
    account_types.included_in?(CURRENCY_RATES_FINISH_ROLES)
  end

  def has_role?(role)
    account_types.include?(role)
  end

  def mob_role?
    has_role?('mob') || has_role?('mob_dep') || has_role?('mob_gb') || has_role?('mob_gb_dep')
  end

  def country_head_role?
    has_role?('country_head') || has_role?('deputy_country_head')
  end

  def brand_roles?
    has_role?('marketing_analyst') || has_role?('distribution_manager')
  end

  private

  def set_default_role
    roles << Role.find_or_create_by(account_type: 'country_manager', full_account_type: 'Country Manager')
  end
end
