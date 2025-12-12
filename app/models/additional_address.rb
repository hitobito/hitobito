# frozen_string_literal: true

#  Copyright (c) 2022-2025,  Eidgenössischer Jodlerverband. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
class AdditionalAddress < ApplicationRecord
  include ContactAccount
  include PostalAddress

  validates_by_schema

  before_validation :copy_name_from_contactable, if: :uses_contactable_name

  def self.predefined_labels
    Settings.additional_address.predefined_labels
  end

  def full_name = name

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
