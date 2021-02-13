# frozen_string_literal: true

#  Copyright (c) 2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.


module MailRelay
  class MailProcessedBeforeError < StandardError
    def initialize(mail_log)
      msg = "Mail with subject '#{mail_log.message.subject}' has already been " \
            "processed before and is skipped. Please remove it manually " \
            "from catch-all inbox and check why it could not be processed.\n" \
            "Mail Hash: #{mail_log.mail_hash}"

      @mail_log = mail_log
      super(msg)
    end
  end
end
