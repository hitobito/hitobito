# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Contactable

  extend ActiveSupport::Concern

  ACCESSIBLE_ATTRS = [:email, :address, :zip_code, :town, :country,
                      phone_numbers_attributes:   [:id, :number, :label, :public, :_destroy],
                      social_accounts_attributes: [:id, :name, :label, :public, :_destroy],
                      additional_emails_attributes: [:id, :email, :label, :public, :mailings,
                                                     :_destroy]]

  included do
    has_many :phone_numbers, as: :contactable, dependent: :destroy
    has_many :social_accounts, as: :contactable, dependent: :destroy
    has_many :additional_emails, as: :contactable, dependent: :destroy

    accepts_nested_attributes_for :phone_numbers, :social_accounts, :additional_emails,
                                  allow_destroy: true

    before_validation :set_self_in_nested
  end


  def ignored_country?
    ['', *Settings.address.ignored_countries].include?(country.to_s.strip.downcase)
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

  module ClassMethods
    def preload_accounts
      includes(:additional_emails, :phone_numbers, :social_accounts)
    end

    def preload_public_accounts
      all.extending(Person::PreloadPublicAccounts)
    end
  end

end
