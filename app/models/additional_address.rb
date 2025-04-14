# frozen_string_literal: true

#  Copyright (c) 2022-2025,  Eidgenössischer Jodlerverband. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: additional_addresses
#
#  id               :bigint           not null, primary key
#  address_care_of  :string
#  contactable_type :string
#  country          :string           not null
#  housenumber      :string(20)
#  label            :string           not null
#  postbox          :string
#  street           :string           not null
#  town             :string           not null
#  zip_code         :string           not null
#  contactable_id   :bigint
#
# Indexes
#
#  idx_on_contactable_id_contactable_type_label_53043e4f10  (contactable_id,contactable_type,label) UNIQUE
#  index_additional_addresses_on_contactable                (contactable_type,contactable_id)
#
class AdditionalAddress < ApplicationRecord
  include ContactAccount
  include PostalAddress

  validates_by_schema

  validates :label, uniqueness: {scope: [:contactable_id, :contactable_type]}

  def self.predefined_labels
    Settings.additional_address.predefined_labels
  end

  def to_s = value

  def value
    street_with_number = [street, housenumber].compact_blank.join(" ")
    town_with_zipcode = [zip_code, town].compact_blank.join(" - ")

    [
      address_care_of,
      street_with_number,
      postbox.presence || town_with_zipcode,
      (country_label unless ignored_country?)
    ].compact_blank.join(", ")
  end

  private

  # to validate zip codes to swiss zip code format when country is nil, we return :ch format as the default
  # option when country is nil
  def zip_country
    self[:country] || :ch
  end
end
