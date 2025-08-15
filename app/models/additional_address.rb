# frozen_string_literal: true

#  Copyright (c) 2022-2025,  Eidgenössischer Jodlerverband. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: additional_addresses
#
#  id                    :bigint           not null, primary key
#  address_care_of       :string
#  contactable_type      :string
#  country               :string           not null
#  housenumber           :string(20)
#  invoices              :boolean          default(FALSE), not null
#  label                 :string           not null
#  name                  :string           not null
#  postbox               :string
#  public                :boolean          default(FALSE), not null
#  street                :string           not null
#  town                  :string           not null
#  uses_contactable_name :boolean          default(TRUE), not null
#  zip_code              :string           not null
#  contactable_id        :bigint
#
# Indexes
#
# rubocop:todo Layout/LineLength
#  idx_on_contactable_id_contactable_type_invoices_45d4363dd7  (contactable_id,contactable_type,invoices) UNIQUE WHERE (invoices = true)
# rubocop:enable Layout/LineLength
# rubocop:todo Layout/LineLength
#  idx_on_contactable_id_contactable_type_label_53043e4f10     (contactable_id,contactable_type,label) UNIQUE
# rubocop:enable Layout/LineLength
#  index_additional_addresses_on_contactable                   (contactable_type,contactable_id)
#
class AdditionalAddress < ApplicationRecord
  include ContactAccount
  include PostalAddress

  validates_by_schema

  before_validation :copy_name_from_contactable, if: :uses_contactable_name

  def self.predefined_labels
    Settings.additional_address.predefined_labels
  end

  def to_s = value

  def value
    street_with_number = [street, housenumber].compact_blank.join(" ")
    town_with_zipcode = [zip_code, town].compact_blank.join(" ")

    [
      name,
      address_care_of,
      street_with_number,
      postbox.presence,
      town_with_zipcode,
      (country_label unless ignored_country?)
    ].compact_blank.join(", ")
  end

  private

  def copy_name_from_contactable
    self.name = contactable.to_s
  end
end
