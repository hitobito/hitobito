# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: event_questions
#
#  id               :integer          not null, primary key
#  admin            :boolean          default(FALSE), not null
#  choices          :string(255)
#  multiple_choices :boolean          default(FALSE), not null
#  question         :text(65535)
#  required         :boolean          default(FALSE), not null
#  event_id         :integer
#
# Indexes
#
#  index_event_questions_on_event_id  (event_id)
#

class Event::Question::AhvNumber < Event::Question

  AHV_NUMBER_REGEX = /\A\d{3}\.\d{4}\.\d{4}\.\d{2}\z/

  def validate_ahv_number
  end

  def validate_answer(answer)
    ahv_number = answer.answer
    return if ahv_number.blank?

    if !AHV_NUMBER_REGEX.match?(ahv_number)
      answer.errors.add(:answer, :must_be_social_security_number_with_correct_format)
      return
    end
    unless checksum_validate(ahv_number).valid?
      answer.errors.add(:answer, :must_be_social_security_number_with_correct_checksum)
    end
  end

def checksum_validate(ahv_number)
    SocialSecurityNumber::Validator.new(number: ahv_number.to_s, country_code: "ch")
  end
end
