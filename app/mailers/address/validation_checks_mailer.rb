# frozen_string_literal: true

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

class Address::ValidationChecksMailer < ApplicationMailer

   CONTENT_ADDRESS_VALIDATION_CHECKS = 'address_validation_checks'.freeze

  def validation_checks(recipient_email, invalid_people)
    @invalid_people = invalid_people

    values = values_for_placeholders(CONTENT_ADDRESS_VALIDATION_CHECKS)

    custom_content_mail(recipient_email, CONTENT_ADDRESS_VALIDATION_CHECKS, values)
  end

  private

  def placeholder_invalid_people
    @invalid_people.map(&:full_name).join(', ')
  end
end
