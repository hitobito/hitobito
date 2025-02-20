# frozen_string_literal: true

#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require_relative Rails.root.join("app", "domain", "countries") # take precedence over a gem

module Contactable
  extend ActiveSupport::Concern

  # rubocop:disable Style/MutableConstant extension point
  ACCESSIBLE_ATTRS = [
    :email, :address_care_of, :street, :housenumber, :postbox, :zip_code, :town, :country, {
      phone_numbers_attributes: [:id, :number, :translated_label, :public, :_destroy],
      social_accounts_attributes: [:id, :name, :translated_label, :public, :_destroy],
      additional_emails_attributes: [:id, :email, :translated_label, :public, :mailings, :_destroy]
    }
  ]
  # rubocop:enable Style/MutableConstant
  if FeatureGate.disabled?("structured_addresses")
    ACCESSIBLE_ATTRS.delete(:address_care_of)
    ACCESSIBLE_ATTRS.delete(:street)
    ACCESSIBLE_ATTRS.delete(:housenumber)
    ACCESSIBLE_ATTRS.delete(:postbox)

  end

  if FeatureGate.disabled?("address_migration")
    ACCESSIBLE_ATTRS << :address
  end

  if FeatureGate.enabled?("address_migration")
    ACCESSIBLE_ATTRS.delete(:address_care_of)
    ACCESSIBLE_ATTRS.delete(:street)
    ACCESSIBLE_ATTRS.delete(:housenumber)
    ACCESSIBLE_ATTRS.delete(:postbox)
  end

  included do
    has_many :phone_numbers, as: :contactable, dependent: :destroy
    has_many :social_accounts, as: :contactable, dependent: :destroy
    has_many :additional_emails, as: :contactable, dependent: :destroy

    belongs_to :location, foreign_key: "zip_code", primary_key: "zip_code", inverse_of: false

    accepts_nested_attributes_for :phone_numbers, :social_accounts, :additional_emails,
      allow_destroy: true

    before_validation :set_self_in_nested

    validates :country, inclusion: Countries.codes, allow_blank: true

    # Configure if zip code should be validated, true by default, can be disabled in wagons
    class_attribute :validate_zip_code, default: true
    validates :zip_code, zipcode: {country_code_attribute: :zip_country}, allow_blank: true, if: :validate_zip_code
  end

  def address
    if FeatureGate.enabled?("structured_addresses") || FeatureGate.enabled?("address_migration")
      parts = [street, housenumber].compact

      if parts.blank?
        if FeatureGate.enabled?("address_migration")
          return self[:address]
        else
          return nil
        end
      end

      parts.join(" ")
    else
      self[:address]
    end
  end

  def country_label
    Countries.label(country)
  end

  def country=(value)
    super(Countries.normalize(value))
  end

  def ignored_country?
    swiss?
  end

  def swiss?
    Countries.swiss?(country)
  end

  def canton
    (swiss? && location&.canton) || nil
  end

  private

  # to validate zip codes to swiss zip code format when country is nil, we return :ch format as the default
  # option when country is nil
  def zip_country
    self[:country] || :ch
  end

  def set_self_in_nested
    # don't try to set self in frozen nested attributes (-> marked for destroy)
    (phone_numbers + social_accounts + additional_emails).each do |e|
      unless e.frozen?
        e.contactable = self
        e.mark_for_destruction if e.value.blank?
      end
    end
  end

  module ClassMethods
    def preload_accounts
      includes(:additional_emails, :phone_numbers, :social_accounts)
    end

    def preload_public_accounts
      all.extending(Person::PreloadPublicAccounts)
    end
  end
end
