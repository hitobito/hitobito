# frozen_string_literal: true

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

class FailureMailer < ApplicationMailer

  CONTENT_BULK_MAIL_TOO_BIG_NOTIFICATION = 'bulk_mail_failure_notification'.freeze

  def validation_checks(sender_email, subject)
    @subject = subject
    compose(sender_email, CONTENT_BULK_MAIL_TOO_BIG_NOTIFICATION)
  end

  def placeholder_subject
    @subject
  end
end
