# frozen_string_literal: true

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module ValidatedEmail

  extend ActiveSupport::Concern

  included do
    validate :assert_valid_email
  end

  def valid_email?(email = self.email)
    Truemail.valid?(email)
  end

  private

  def assert_valid_email
    self.email = email.presence
    return if !email || !email_changed? || valid_email?(email)

    # Send a sentry Notification if even the base mail which shoul be valid is invalid at the moment
    alert_sentry(email) unless valid_email?(Settings.root_email)

    errors.add(:email, :invalid)
  end

  def alert_sentry(email)
    Raven.capture_message(
      'Truemail does not work as expected',
      extra: {
        verifier_email: Truemail.configure.verifier_email,
        validated_email: email
      })
  end

end
