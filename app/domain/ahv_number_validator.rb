# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AhvNumberValidator < ActiveModel::EachValidator
  AHV_NUMBER_REGEX = /\A\d{3}\.\d{4}\.\d{4}\.\d{2}\z/

  def validate_each(record, attribute, value)
    return if value.blank?

    if !AHV_NUMBER_REGEX.match?(value)
      record.errors.add(attribute, :must_be_social_security_number_with_correct_format)
      return
    end
    unless checksum_validate(value).valid?
      record.errors.add(attribute, :must_be_social_security_number_with_correct_checksum)
    end
  end

  def checksum_validate(ahv_number)
    SocialSecurityNumber::Validator.new(number: ahv_number.to_s, country_code: "ch")
  end
end
