# frozen_string_literal: true

#  Copyright (c) 2022, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Messages::Errors
  class MailProcessedBefore < StandardError
    def initialize(mail_log)
      msg = "Mail with subject '#{mail_log.message.subject}' has already been " \
            'processed before. It has been moved to the failed folder. Please ' \
            "check why it could not be processed.\n" \
            "Mail Hash: #{mail_log.mail_hash}"

      @mail_log = mail_log
      super(msg)
    end
  end
end
