# encoding: utf-8

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.
#
# == Schema Information
#
# Table name: addresses
#
#  id               :bigint           not null, primary key
#  numbers          :text(16777215)
#  state            :string(128)      not null
#  street_long      :string(128)      not null
#  street_long_old  :string(128)      not null
#  street_short     :string(128)      not null
#  street_short_old :string(128)      not null
#  town             :string(128)      not null
#  zip_code         :integer          not null
#
# Indexes
#
#  index_addresses_on_zip_code_and_street_short  (zip_code,street_short)
#

class Address < ActiveRecord::Base
  serialize :numbers, Array

  validates_by_schema

  scope :list, -> { order(:street_short, "LENGTH(numbers) DESC") }

  def self.for(zip_code, street)
    where(zip_code: zip_code).
      where("LOWER(street_short) = :street OR LOWER(street_short_old) = :street OR " \
            "LOWER(street_long) = :street OR LOWER(street_long_old) = :street",
        street: street.to_s.downcase)
  end

  def to_s(_format = :default)
    "#{street_short} #{zip_code} #{town}"
  end

  def as_typeahead
    {id: id,
     label: to_s,
     town: town,
     zip_code: zip_code,
     street: street_short,
     state: state}
  end

  def as_typeahead_with_number(number)
    {id: id,
     label: label_with_number(number),
     town: town,
     zip_code: zip_code,
     street: street_short,
     state: state,
     number: number}
  end

  def label_with_number(number)
    "#{street_short} #{number} #{town}"
  end
end
