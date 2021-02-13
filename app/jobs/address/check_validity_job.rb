# frozen_string_literal: true

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

class Address::CheckValidityJob < RecurringJob
  run_every 1.day

  def perform
    invalid_people = Contactable::AddressValidator.new.validate_people

    return if invalid_people.empty? || Settings.addresses.validity_job_notification_emails.blank?

    invalid_names = invalid_people.map(&:full_name).join(", ")
    Settings.addresses.validity_job_notification_emails.each do |mail_address|
      Address::ValidationChecksMailer.validation_checks(mail_address, invalid_names).deliver_later
    end
  end
end
