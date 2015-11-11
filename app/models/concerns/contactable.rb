# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Contactable

  extend ActiveSupport::Concern

  ACCESSIBLE_ATTRS = [:email, :address, :zip_code, :town, :country,
                      phone_numbers_attributes:
                        [:id, :number, :translated_label, :public, :_destroy],
                      social_accounts_attributes:
                        [:id, :name, :translated_label, :public, :_destroy],
                      additional_emails_attributes:
                        [:id, :email, :translated_label, :public, :mailings, :_destroy]]

  included do
    has_many :phone_numbers, as: :contactable, dependent: :destroy
    has_many :social_accounts, as: :contactable, dependent: :destroy
    has_many :additional_emails, as: :contactable, dependent: :destroy

    belongs_to :location, foreign_key: 'zip_code', primary_key: 'zip_code'

    accepts_nested_attributes_for :phone_numbers, :social_accounts, :additional_emails,
                                  allow_destroy: true

    before_validation :set_self_in_nested

    validates :country, inclusion: ISO3166::Data.codes, allow_blank: true
    validate :assert_is_valid_swiss_post_code
  end

  def country_label
    c = ISO3166::Country.new(country)
    c ? c.translations[I18n.locale.to_s] || c.name.presence : country
  end

  def country=(value)
    normalized = value.to_s.strip.downcase
    if normalized.size > 2
      super(value)
      ISO3166::Country.translations(I18n.locale).each do |key, label|
        super(key) if label.downcase == normalized
      end
    else
      super(value.to_s.strip.upcase)
    end

    value
  end

  def ignored_country?
    swiss?
  end

  def swiss?
    ['', 'ch'].include?(country.to_s.strip.downcase)
  end

  def canton
    (swiss? && location && location.canton) || nil
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

  def assert_is_valid_swiss_post_code
    if zip_code.present? && swiss? && !zip_code.to_s.match(/^\d{4}$/)
      errors.add(:zip_code)
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
