# frozen_string_literal: true

#  Copyright (c) 2017-2024, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class IbanValidator < ActiveModel::EachValidator
  IBAN_REGEX = /\A[A-Z]{2}[0-9]{2}\s?([A-Z]|[0-9]\s?){12,30}\z/

  def validate_each(record, attribute, value)
    unless valid_iban?(value)
      record.errors.add(attribute, I18n.t("errors.messages.invalid_iban"))
    end
  end

  # validates iban to match regex and performs checksum lookup with modulo 97 act
  def valid_iban?(iban)
    iban = iban.delete(" ")

    return false unless iban.match?(IBAN_REGEX)

    rearranged_iban = ((iban.slice(4..-1) + iban.slice(0..3)).slice(0..-3) + "00").chars.map do |char|
      char.match?(/[A-Z]/) ? (char.ord - "A".ord + 10).to_s : char
    end.join

    iban[2..3].to_i == 98 - rearranged_iban.to_i % 97
  end
end
