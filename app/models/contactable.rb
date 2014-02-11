# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Contactable

  extend ActiveSupport::Concern

  included do

    attr_accessible :email, :address, :zip_code, :town, :country,
                    :phone_numbers_attributes, :social_accounts_attributes

    has_many :phone_numbers, as: :contactable, dependent: :destroy
    has_many :social_accounts, as: :contactable, dependent: :destroy

    scope :preload_accounts, includes(:phone_numbers, :social_accounts)
    scope :preload_public_accounts, scoped.extending(Person::PreloadPublicAccounts)

    accepts_nested_attributes_for :phone_numbers, :social_accounts, allow_destroy: true

    before_validation :set_self_in_nested
  end


  def ignored_country?
    ['', *Settings.address.ignored_countries].include?(country.to_s.strip.downcase)
  end

  private

  def set_self_in_nested
    # don't try to set self in frozen nested attributes (-> marked for destroy)
    (phone_numbers + social_accounts).each { |e| e.contactable = self unless e.frozen? }
  end

end
