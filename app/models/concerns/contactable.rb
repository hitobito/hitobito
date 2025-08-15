# frozen_string_literal: true

#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require_relative Rails.root.join("app", "domain", "countries") # take precedence over a gem

module Contactable
  include PostalAddress

  extend ActiveSupport::Concern

  # rubocop:disable Style/MutableConstant extension point
  ACCESSIBLE_ATTRS = [
    :email, :address_care_of, :street, :housenumber, :postbox, :zip_code, :town, :country, {
      phone_numbers_attributes: [:id, :number, :translated_label, :public, :_destroy],
      social_accounts_attributes: [:id, :name, :translated_label, :public, :_destroy],
      additional_emails_attributes: [:id, :email, :translated_label, :public, :mailings, :invoices,
        :_destroy],
      additional_addresses_attributes: [
        :id,
        :name,
        :translated_label,
        :street,
        :housenumber,
        :zip_code,
        :town,
        :country,
        :address_care_of,
        :postbox,
        :uses_contactable_name,
        :invoices,
        :public,
        :_destroy
      ]
    }
  ]
  # rubocop:enable Style/MutableConstant

  included do
    has_many :phone_numbers, as: :contactable, dependent: :destroy
    has_many :social_accounts, as: :contactable, dependent: :destroy
    has_many :additional_emails, as: :contactable, dependent: :destroy
    has_many :additional_addresses, as: :contactable, dependent: :destroy

    belongs_to :location, foreign_key: "zip_code", primary_key: "zip_code", inverse_of: false

    # rubocop:todo Layout/LineLength
    accepts_nested_attributes_for :phone_numbers, :social_accounts, :additional_emails, :additional_addresses,
      # rubocop:enable Layout/LineLength
      allow_destroy: true

    before_validation :set_self_in_nested

    validates :country, inclusion: Countries.codes, allow_blank: true

    # Configure if zip code should be validated, true by default, can be disabled in wagons
    class_attribute :validate_zip_code, default: true
    validates :zip_code, zipcode: {country_code_attribute: :zip_country}, allow_blank: true,
      if: :validate_zip_code
    validate :assert_max_one_additional_invoice_address
    validate :assert_additional_address_labels_are_unique, if: -> { additional_addresses.any? }
  end

  private

  def set_self_in_nested
    # don't try to set self in frozen nested attributes (-> marked for destroy)
    (phone_numbers + social_accounts + additional_emails).each do |e|
      unless e.frozen?
        e.contactable = self
        e.mark_for_destruction if e.value.blank?
      end
    end
  end

  def assert_max_one_additional_invoice_address
    if additional_addresses.count(&:invoices) > 1
      errors.add(:base, :max_one_additional_invoice_address)
    end
  end

  def assert_additional_address_labels_are_unique
    if additional_addresses.map(&:label).tally.values.max > 1
      errors.add(:base, :additional_address_labels_must_be_unique)
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
